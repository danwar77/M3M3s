# Supabase Storage Guide for Flutter

This guide provides instructions for setting up Supabase Storage for your meme application and integrating it with your Flutter app using the `supabase_flutter` package. This includes creating storage buckets, defining access policies, and implementing file upload, download, and management functionalities.

## 1. Introduction to Supabase Storage

Supabase Storage allows you to store and serve large files like images, videos, and other user-generated content. It works seamlessly with Supabase Auth for securing access to your files using policies.

For our meme application, we'll primarily use Storage for:
*   Storing predefined meme template images.
*   Storing user-uploaded custom images for memes.
*   Storing final generated meme images saved by users.

## 2. Supabase Project Configuration (Dashboard & SQL)

### 2.1. Bucket Creation

Buckets are containers for your files. You can create them via the Supabase Dashboard:

1.  Navigate to `Storage` in your Supabase project.
2.  Click `Create new bucket`.

**Recommended Buckets:**

*   **`templates` Bucket:**
    *   **Purpose:** Stores images for predefined meme templates.
    *   **Public/Private:** This bucket can be made **public** if all templates are globally accessible and don't require specific user permissions to view. If some templates are premium or restricted, you might make it private and use signed URLs or more granular RLS (though public is simpler for global templates).
    *   **Example:** If public, anyone can read the template images directly using their public URL.

*   **`user_memes` Bucket:**
    *   **Purpose:** Stores final meme images generated and saved by users, as well as custom images uploaded by users to create memes.
    *   **Public/Private:** This bucket should generally be **private**. Access to files will be controlled by RLS policies, ensuring users can only access their own images or images explicitly made public through application logic (e.g., by creating signed URLs).

### 2.2. Storage Access Policies (SQL)

Storage policies control who can access and manipulate files within your buckets. These are defined using SQL and are similar to Row Level Security policies for database tables. You can add these policies in the Supabase SQL Editor (`Database` -> `SQL Editor` -> `New query`).

**Important Note:** `storage.objects` is the table on which these policies are applied. `bucket_id` refers to the name of your bucket.

#### **`templates` Bucket Policies:**

*   **Option 1: Public Read Access (Simplest for global templates)**
    If the `templates` bucket is marked as "Public" in the dashboard, files are accessible via their public URL. You might still want an explicit policy if you need finer control or if the bucket isn't fully public from the dashboard settings.

    ```sql
    -- Allow public read access to all files in the 'templates' bucket
    CREATE POLICY "Public read access for template images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'templates');
    ```

*   **Option 2: Admin/Specific Role for Uploads/Updates/Deletes**
    Typically, templates are managed by administrators or a specific role.

    ```sql
    -- Example: Allow users with a custom 'admin' role (via JWT claims) to manage template files
    -- Assumes you have a way to set 'user_role' in your custom JWT claims.
    CREATE POLICY "Admins can manage template files"
    ON storage.objects FOR INSERT, UPDATE, DELETE
    USING (auth.jwt() ->> 'user_role' = 'admin' AND bucket_id = 'templates')
    WITH CHECK (auth.jwt() ->> 'user_role' = 'admin' AND bucket_id = 'templates');

    -- Alternatively, if specific authenticated users can upload (less common for global templates):
    -- CREATE POLICY "Authenticated users can upload to templates bucket"
    -- ON storage.objects FOR INSERT
    -- WITH CHECK (auth.role() = 'authenticated' AND bucket_id = 'templates');
    ```

#### **`user_memes` Bucket Policies:**

This bucket should be private, and access should be tightly controlled. We'll often organize files by user ID.

*   **Users can upload their own memes/images:**
    Files are typically stored under a path like `user_id/filename.ext`.

    ```sql
    -- Policy: Allows authenticated users to upload files to the 'user_memes' bucket.
    -- It's highly recommended to scope uploads to a user-specific folder.
    CREATE POLICY "Users can upload their own meme images"
    ON storage.objects FOR INSERT
    WITH CHECK (
      auth.uid() IS NOT NULL AND -- User must be authenticated
      bucket_id = 'user_memes' AND
      auth.uid()::text = (storage.foldername(name))[1] -- Ensures the first folder in the path is the user's ID
      -- Example path: user_id/some_folder/image.png -> (storage.foldername(name))[1] extracts 'user_id'
    );
    ```
    *Note on `(storage.foldername(name))[1]`: This extracts the first part of the file path (e.g., `user_id` from `user_id/my_meme.png`). Ensure your Flutter app uploads files using this path structure.*

*   **Users can read/download their own memes/images:**

    ```sql
    CREATE POLICY "Users can read their own meme images"
    ON storage.objects FOR SELECT
    USING (
      auth.uid() IS NOT NULL AND
      bucket_id = 'user_memes' AND
      auth.uid()::text = (storage.foldername(name))[1] -- User can only read from their own folder
    );
    ```

*   **Users can delete their own memes/images:**

    ```sql
    CREATE POLICY "Users can delete their own meme images"
    ON storage.objects FOR DELETE
    USING (
      auth.uid() IS NOT NULL AND
      bucket_id = 'user_memes' AND
      auth.uid()::text = (storage.foldername(name))[1] -- User can only delete from their own folder
    );
    ```

*   **Users can update their own memes/images (Optional, if updates are allowed):**

    ```sql
    CREATE POLICY "Users can update their own meme images"
    ON storage.objects FOR UPDATE
    USING (
      auth.uid() IS NOT NULL AND
      bucket_id = 'user_memes' AND
      auth.uid()::text = (storage.foldername(name))[1]
    )
    WITH CHECK (
      auth.uid() IS NOT NULL AND
      bucket_id = 'user_memes' AND
      auth.uid()::text = (storage.foldername(name))[1]
    );
    ```

*   **(Optional) Public Read for Specific Memes:**
    Directly linking Storage RLS to metadata in a database table (e.g., `memes.visibility = 'public'`) is complex. Common approaches:
    1.  **Signed URLs (Recommended for most cases):** Generate short-lived public URLs for private files when needed. The Flutter app requests a signed URL from the backend (or generates it if client-side generation is deemed secure enough for the use case, though backend is safer).
    2.  **Backend Serves Files:** Create a backend function (e.g., Supabase Edge Function) that fetches the file from storage *after* checking the `memes` table for public visibility and then serves it to the client.
    3.  **Separate Public Bucket:** If many memes become public, you could move/copy them to a dedicated public bucket (adds complexity).

    For this guide, we'll focus on users accessing their own private files and using signed URLs for controlled sharing/display.

## 3. Flutter Client Integration (`supabase_flutter`)

Ensure `supabase_flutter` is initialized in your `main.dart` as covered in the Auth guide.

### 3.1. Accessing the Storage Client

```dart
final supabase = Supabase.instance.client;
final storage = supabase.storage; // Or Supabase.instance.client.storage;
```

### 3.2. Uploading Files

#### Uploading from a `File` Object (e.g., using `image_picker`)

This is common for user-uploaded custom images.

```dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
// Assuming image_picker is used to get the File object

Future<String?> uploadCustomImage(File imageFile, String userId) async {
  final supabaseStorage = Supabase.instance.client.storage;
  try {
    // Ensure a unique file name, possibly including a timestamp or UUID
    final fileExtension = imageFile.path.split('.').last.toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.uri.pathSegments.last}';
    final filePath = '$userId/uploads/$fileName'; // Path: user_id/uploads/image_name.ext

    await supabaseStorage.from('user_memes').upload(
      filePath,
      imageFile,
      fileOptions: FileOptions(cacheControl: '3600', upsert: false), // Optional: Set cache control, prevent overwrite
    );
    print('Upload successful: $filePath');
    return filePath; // Return the Supabase storage path to save in your database
  } on StorageException catch (e) {
    print('Error uploading image: ${e.message}');
    // Handle specific errors: e.g., e.statusCode == '409' for conflict if upsert is false
    return null;
  } catch (e) {
    print('Unexpected error uploading image: $e');
    return null;
  }
}
```

#### Uploading Raw Bytes (`Uint8List`)

Useful for memes generated on the client-side (e.g., from a canvas or widget).

```dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String?> uploadGeneratedMemeData(Uint8List memeData, String userId, String imageExtension) async {
  final supabaseStorage = Supabase.instance.client.storage;
  try {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$imageExtension';
    // Path: user_id/generated/timestamp.ext
    final filePath = '$userId/generated/$fileName';

    final response = await supabaseStorage.from('user_memes').uploadBinary(
      filePath,
      memeData,
      fileOptions: FileOptions(
        cacheControl: '3600',
        upsert: false,
        contentType: 'image/$imageExtension' // Important for correct display
      ),
    );
    print('Upload binary successful: $filePath');
    return filePath; // Return the Supabase storage path
  } on StorageException catch (e) {
    print('Error uploading generated meme: ${e.message}');
    return null;
  } catch (e) {
    print('Unexpected error uploading generated meme: $e');
    return null;
  }
}
```

### 3.3. Downloading Files / Getting URLs

#### Public URLs (for public buckets or publicly accessible files)

If the `templates` bucket is public:

```dart
String getPublicTemplateUrl(String templateImagePath) {
  // templateImagePath is the path within the bucket, e.g., 'classic/drake.png'
  try {
    final publicUrl = Supabase.instance.client.storage
        .from('templates') // Bucket name
        .getPublicUrl(templateImagePath);
    return publicUrl;
  } catch (e) {
    print('Error getting public URL for template: $e');
    return ''; // Return a placeholder or handle error
  }
}

// Usage with Flutter's Image widget:
// Image.network(getPublicTemplateUrl('path/to/your/template.png'))
```

#### Signed URLs (for private files - Recommended for `user_memes`)

Signed URLs provide temporary access to private files.

```dart
Future<String?> createSignedMemeUrl(String memePath) async {
  // memePath is the full path within the 'user_memes' bucket, e.g., 'user_id/generated/meme.png'
  try {
    final signedUrl = await Supabase.instance.client.storage
        .from('user_memes') // Bucket name
        .createSignedUrl(
          memePath,
          60 * 60, // Expiry time in seconds (e.g., 1 hour)
        );
    return signedUrl;
  } on StorageException catch (e) {
    print('Error creating signed URL: ${e.message}');
    return null;
  } catch (e) {
    print('Unexpected error creating signed URL: $e');
    return null;
  }
}

// Usage with Flutter's Image widget:
// FutureBuilder<String?>(
//   future: createSignedMemeUrl('user_id/path/to/your/meme.png'),
//   builder: (context, snapshot) {
//     if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
//       return Image.network(snapshot.data!);
//     }
//     if (snapshot.hasError) {
//       return Text('Error loading image');
//     }
//     return CircularProgressIndicator();
//   },
// )
```

### 3.4. Listing Files (Less common for this app's direct client needs)

You can list files within a bucket or a specific folder. This might be more useful for admin panels.

```dart
Future<void> listUserFiles(String userId) async {
  try {
    final fileObjects = await Supabase.instance.client.storage
        .from('user_memes')
        .list(path: '$userId/generated/'); // List files in user_id/generated/ folder

    for (final file in fileObjects) {
      print('File: ${file.name}, ID: ${file.id}, Size: ${file.metadata?['size']}');
    }
  } on StorageException catch (e) {
    print('Error listing files: ${e.message}');
  }
}
```

### 3.5. Deleting Files

```dart
Future<bool> deleteMemeImage(String memePath) async {
  // memePath is the full path within the 'user_memes' bucket, e.g., 'user_id/generated/meme.png'
  try {
    await Supabase.instance.client.storage
        .from('user_memes') // Bucket name
        .remove([memePath]); // Takes a list of file paths to remove
    print('File deleted: $memePath');
    return true;
  } on StorageException catch (e) {
    print('Error deleting file: ${e.message}');
    return false;
  } catch (e) {
    print('Unexpected error deleting file: $e');
    return false;
  }
}
```
**Important:** When a user deletes a meme record from the database, you should also delete the corresponding image file from Supabase Storage to avoid orphaned files. This can be done via a backend function/trigger or by the client app upon successful database deletion.

## 4. File Naming and Organization Strategy

A consistent file organization strategy is crucial, especially when using RLS policies that rely on file paths.

*   **`templates` bucket:**
    *   Organize by category or theme if needed: `category/template_name.png` (e.g., `classic/drake_hotline.png`).
    *   Use descriptive, URL-friendly names.

*   **`user_memes` bucket (Private):**
    *   **User-Specific Root Folder:** Always store files under a folder named with the `user_id`. This simplifies RLS policy creation (`auth.uid()::text = (storage.foldername(name))[1]`).
        *   Path structure: `[USER_ID]/[SUBFOLDER]/[FILENAME.EXT]`
    *   **Subfolders for Organization:**
        *   `[USER_ID]/uploads/`: For original custom images uploaded by the user.
            *   Example: `user_abc123/uploads/my_cat_pic_1678886400000.jpg`
        *   `[USER_ID]/generated/`: For memes generated and saved by the user.
            *   Example: `user_abc123/generated/meme_def456_1678886500000.png`
    *   **File Naming:**
        *   Use unique names to prevent collisions. A common pattern is `[original_name_or_type]_[timestamp_or_uuid].[extension]`.
        *   Sanitize filenames if they are user-provided to remove special characters.

## 5. Error Handling Notes

*   **`StorageException`:** Supabase Storage client methods throw `StorageException` for errors. Catch this specific exception to handle storage-related issues.
*   **Status Codes:** The `StorageException` may contain a `statusCode` (often a string like '404' or '403') that can give more insight into the error.
*   **Permissions:** Ensure your RLS policies for Storage are correctly set up. Incorrect policies are a common source of errors (often resulting in 403 Forbidden type errors). Test policies thoroughly using the Supabase SQL Editor or by making test requests.
*   **Network Issues:** File uploads/downloads can be affected by network connectivity. Implement appropriate user feedback and retry mechanisms if necessary.

This guide covers the essentials for integrating Supabase Storage into your Flutter meme application. Always refer to the official [Supabase Storage documentation](https://supabase.io/docs/guides/storage) and [Supabase Flutter Storage API](https://supabase.io/docs/reference/dart/storage-from-list) for the most up-to-date information and advanced features.
```
