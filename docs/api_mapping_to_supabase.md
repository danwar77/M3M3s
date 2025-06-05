# OpenAPI Endpoint Mapping to Supabase Architecture

## Introduction

This document maps the functionalities defined in the `openapi.yaml` (our initial API contract) to the new Supabase-centric backend architecture. It outlines how each original API endpoint's purpose is achieved using Supabase's built-in features (Database, Authentication, Storage) and planned Supabase Edge Functions.

---

## 1. Authentication Endpoint

### Original: `POST /api/v1/auth/verify_token`

*   **Original Purpose:**
    Verifies a Firebase ID token sent from the client. If valid, the backend uses the decoded token to identify the user, potentially creating a user record in a custom database table (`profiles`) or retrieving existing user data. It was also intended to return user profile information.

*   **Supabase Mapping & Functionality:**
    *   **Token Verification & Session Management:** This is **implicitly handled by Supabase Auth** whenever the Flutter client (`supabase_flutter`) makes an authenticated request to any Supabase service (Database, Storage, Functions). The `supabase_flutter` library manages the user's session and automatically includes the JWT (Supabase's own, not Firebase's directly after initial sign-in if using Supabase Auth fully) in requests. If the original intent was to use Firebase as the primary IdP and Supabase as just a backend, Supabase Auth can be configured to accept Firebase JWTs (requires specific setup). For this plan, we assume Supabase Auth is the primary system.
    *   **User Identification:** Supabase Auth automatically identifies the user via their JWT. The user's ID (`auth.uid()`) is available in database policies and can be accessed in Edge Functions.
    *   **User Profile Creation/Retrieval:**
        *   User creation in `auth.users` is handled by Supabase Auth during sign-up (`supabase.auth.signUp()`).
        *   Our custom `public.profiles` table is populated/updated via:
            1.  **Trigger:** An SQL trigger (`handle_new_user` defined in `schema.sql` and `supabase_auth_guide.md`) automatically creates a basic profile entry in `public.profiles` when a new user signs up in `auth.users`.
            2.  **Direct DB Calls:** The Flutter client can directly query (`select`) or modify (`update`) the `public.profiles` table for the authenticated user, subject to RLS policies.
                *   Example: `Supabase.instance.client.from('profiles').select().eq('id', supabase.auth.currentUser!.id).single()`
    *   **Response Data (`AuthVerificationResponse`):**
        *   `userId`, `firebaseUid` (now Supabase UID), `email`, `displayName`: This data is available from `Supabase.instance.client.auth.currentUser` on the client after login, and from the `profiles` table.
        *   `isNewUser`: This can be inferred on the client after sign-up if the user object is returned for the first time, or by checking if a profile needed to be created.
        *   `profile`: Fetched directly from the `profiles` table by the client.

*   **Notes/Differences:**
    *   There is **no direct, one-to-one equivalent custom API endpoint** needed for `/auth/verify_token` in the Supabase model if Supabase Auth is primary. The Supabase client library and backend handle session verification transparently.
    *   The Flutter client will interact with `supabase.auth` for login/signup and then directly with the `profiles` table for profile data, secured by RLS.
    *   If the original requirement was specifically to validate a *Firebase* token to then mint a *Supabase* session, an Edge Function could be created for this exchange, but this adds complexity and is usually only needed if migrating from Firebase Auth gradually or using Firebase as a primary IdP. Our current plan assumes Supabase Auth handles user identity.

---

## 2. Meme Generation Endpoint

### Original: `POST /api/v1/memes/generate`

*   **Original Purpose:**
    Takes user text (and optionally a template ID), performs text analysis, selects/generates a template/image, and returns the resulting meme or necessary information (image URL, metadata like tone, keywords).

*   **Supabase Mapping & Functionality:**
    This endpoint's functionality is now primarily handled by Supabase Edge Functions and direct client interactions with Supabase Storage/Database.
    *   **Text Analysis & Template Suggestion:**
        *   Implemented by the **`get-meme-suggestions` Supabase Edge Function**.
        *   The Flutter client calls this function: `supabase.functions.invoke('get-meme-suggestions', body: {'text': userText})`.
        *   The Edge Function performs NLP (via external API) and queries the `templates` table in Supabase DB to find matches.
        *   Returns `analyzedText` (tone, keywords) and `suggestedTemplates` (template IDs, names, image URLs from `templates` table, match scores).
    *   **AI Image Generation (If feature is implemented):**
        *   Implemented by the **`generate-ai-image` Supabase Edge Function**.
        *   Called by the Flutter client if the user chooses AI generation: `supabase.functions.invoke('generate-ai-image', body: {'prompt': imagePrompt})`.
        *   Returns `imageUrl` (from AI service or after upload to Supabase Storage) and metadata.
    *   **Meme Image URL & Rendering:**
        *   **Predefined Template + Client-Side Rendering:**
            1.  Flutter client gets template suggestions from `get-meme-suggestions` (including `imageUrl` for templates, which points to Supabase Storage).
            2.  User selects a template.
            3.  Flutter client fetches the template image directly from Supabase Storage (using the public URL if `templates` bucket is public, or a signed URL if private).
            4.  Text (from user or `analyzedText`) is rendered onto the image client-side.
            5.  If saved, the client uploads the final rendered image to the `user_memes` bucket in Supabase Storage.
        *   **AI-Generated Image:**
            1.  The `generate-ai-image` Edge Function returns an `imageUrl`. This image might already be stored in Supabase Storage by the function.
            2.  Text can be overlaid client-side if needed.
    *   **Metadata (tone, keywords):**
        *   Returned directly by the `get-meme-suggestions` Edge Function as part of its response.

*   **Notes/Differences:**
    *   The single, monolithic `/api/v1/memes/generate` endpoint is decomposed.
    *   The client orchestrates the process:
        1.  Call `get-meme-suggestions` (Edge Function).
        2.  (Optional) If AI generation chosen, call `generate-ai-image` (Edge Function).
        3.  Fetch template images (Supabase Storage via DB URLs).
        4.  Render meme (client-side).
        5.  Upload final image (Supabase Storage).
    *   This provides more flexibility but involves more client-side coordination. The `MemeGenerationResponse` schema from `openapi.yaml` is now partially fulfilled by the output of `get-meme-suggestions` and `generate-ai-image`, and client-side actions.

---

## 3. Template Listing Endpoint

### Original: `GET /api/v1/templates`

*   **Original Purpose:**
    Returns a paginated list of available predefined meme templates, supporting sorting and filtering by tags or search terms.

*   **Supabase Mapping & Functionality:**
    *   This functionality is mapped directly to **Supabase Database API calls** on the `templates` table from the Flutter client.
    *   **Fetching Data:** `supabase.client.from('templates').select('id, name, thumbnail_url, preview_url, tags, category, text_areas, popularity_score, created_at')`
    *   **Pagination:** Implemented using `.range(from, to)` and by calculating `currentPage`, `totalPages`, `totalItems` on the client or with a helper `.rpc()` database function for counts. `PaginationInfo` schema from `openapi.yaml` is constructed client-side or by the RPC.
    *   **Sorting:** Implemented using `.order('column', ascending: true/false)`.
    *   **Filtering:**
        *   Tags: `.cs('tags', ['tag1', 'tag2'])` (if `tags` is an array type) or `.like('tags_text_col', '%tag1%')` (if tags are stored as a single string, not recommended).
        *   Search (name, description): `.or(f'name.ilike.%${searchTerm}%,description.ilike.%${searchTerm}%')`.
    *   RLS policies on the `templates` table ensure appropriate read access (e.g., public read).

*   **Notes/Differences:**
    *   No custom Edge Function is generally needed for this. The client directly queries the database.
    *   The structure of the response (`TemplateListResponse` containing `PaginationInfo` and `templates` array) will be assembled by the Flutter client based on the data retrieved from Supabase and the total count (which might require a separate count query, e.g., `supabase.client.from('templates').select('*', { count: 'exact', head: true })`).

---

## 4. Meme Saving Endpoint

### Original: `POST /api/v1/memes`

*   **Original Purpose:**
    Saves the details of a user-generated or edited meme, including its image reference, text, template used, and associates it with a user.

*   **Supabase Mapping & Functionality:**
    *   This functionality is mapped directly to **Supabase Database API calls** and **Supabase Storage uploads** from the Flutter client.
    1.  **Image Upload:**
        *   If the meme image was rendered client-side or is a new custom image, the Flutter app first uploads it to the `user_memes` bucket in Supabase Storage (e.g., `user_id/generated/timestamp.png`).
        *   The `uploadMemeImage` or `uploadGeneratedMemeData` functions (from `supabase_storage_guide.md`) would be used.
        *   This returns a `storagePath` or full `imageUrl`.
    2.  **Metadata Insertion:**
        *   The Flutter client then inserts a new record into the `memes` table using the Supabase Database API.
        *   `supabase.client.from('memes').insert({ ... })`
        *   The data payload for insertion will match the `MemeSaveRequest` schema (from `openapi.yaml`), including the `imageUrl` obtained from Supabase Storage, `user_id` (from `auth.currentUser`), `text_input` (JSONB), `template_id` (if used), `tags`, `visibility`, etc.
    *   RLS policies on the `memes` table ensure users can only insert memes linked to their own `user_id`.

*   **Notes/Differences:**
    *   No custom Edge Function is needed for the core save operation.
    *   The client handles the two-step process: image upload to Storage, then metadata insert to Database.
    *   The `SavedMemeResponse` (from `openapi.yaml`) will be similar to the data returned by the `.insert({...}).select()` call.

---

## 5. User Meme History Endpoint

### Original: `GET /api/v1/users/{userId}/memes`

*   **Original Purpose:**
    Returns a paginated list of memes saved by the specified user.

*   **Supabase Mapping & Functionality:**
    *   This functionality is mapped directly to **Supabase Database API calls** on the `memes` table from the Flutter client.
    *   **Fetching Data:** `supabase.client.from('memes').select('...fields matching SavedMemeResponse...').eq('user_id', userId)`
    *   **Authorization:** RLS policies on the `memes` table are crucial here.
        *   `CREATE POLICY "Users can select their own memes" ON memes FOR SELECT USING (auth.uid() = user_id);`
        *   This ensures that a request for `/users/{userId}/memes` will only return data if the authenticated user's ID (`auth.uid()`) matches the `{userId}` in the query, or if an admin override policy exists.
    *   **Pagination:** Implemented using `.range(from, to)` and `.order()`.
    *   **Filtering (e.g., by `visibility`):** Client can add additional filters like `.eq('visibility', 'public')` if needed.

*   **Notes/Differences:**
    *   No custom Edge Function is generally needed.
    *   RLS is the primary mechanism for ensuring data privacy and correct access.
    *   The client constructs the paginated list and `PaginationInfo` similarly to the `/templates` endpoint.

---

## Gap Analysis

*   **Functionalities Covered:** All core functionalities defined in `openapi.yaml` (auth verification/user sync, meme generation assistance, template listing, meme saving, meme history) are mapped to the Supabase architecture.
    *   Auth: Handled by Supabase Auth and client interactions.
    *   Complex logic (NLP, AI suggestions): Moved to Supabase Edge Functions (`get-meme-suggestions`, `generate-ai-image`).
    *   Direct data operations (listing templates, saving memes, fetching history): Handled by direct client calls to Supabase Database API, secured by RLS.
    *   Image storage: Handled by Supabase Storage, with client managing uploads and RLS securing access.

*   **Potential Gaps from Original Broad Issue Description:**
    *   The original issue description mentioned "Post-Procesamiento (UI de Edición en Flutter)". This is a client-side responsibility. Saving the results of such editing is covered by the "Save Meme" functionality.
    *   "Recomendaciones (Sugerencias IA)": Covered by the `get-meme-suggestions` Edge Function.
    *   "Interacción Social (Comentarios, Likes, Compartir)": These features were not detailed in the `openapi.yaml` provided. If needed, they would require new tables in `schema.sql` (e.g., `comments`, `likes`) and corresponding DB API calls from the client, secured by RLS. Sharing might involve updating meme `visibility` or using signed URLs.

*   **Simplifications with Supabase:**
    *   **Reduced Need for Custom Backend Endpoints:** Many operations that would have required custom backend endpoints (like CRUD on templates or memes) are now direct database calls from the client, simplified and secured by Supabase's PostgREST interface and RLS.
    *   **Integrated Auth:** Authentication is deeply integrated, and user identity (`auth.uid()`) is readily available for RLS without manual token processing in every function/endpoint.
    *   **Managed Services:** Storage and database are managed services, reducing boilerplate.

*   **Differences in Approach:**
    *   **Orchestration:** The `POST /api/v1/memes/generate` endpoint, which was originally a single API call, is now a more orchestrated process involving one or two Edge Function calls and client-side logic/rendering. This is a common pattern when moving from a monolithic backend endpoint to a more granular, service-oriented approach with serverless functions and client-side capabilities.
    *   **Client Responsibilities:** The Flutter client takes on more responsibility for orchestrating calls and assembling data from different Supabase services (e.g., calling an Edge Function, then fetching an image from Storage, then rendering).

## Conclusion

The Supabase-centric architecture effectively covers all functionalities outlined in the `openapi.yaml`. The primary shift is from custom backend API endpoints for all operations to a model where:
*   Direct database and storage operations are performed by the client, secured by RLS.
*   Complex or sensitive operations requiring server-side execution or third-party integrations are handled by Supabase Edge Functions.
*   Authentication is seamlessly integrated into the Supabase ecosystem.

This mapping provides a clear path for implementing the application's backend logic using Supabase tools.

