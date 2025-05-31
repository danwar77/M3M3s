-- Supabase Database Schema for Meme Generation App

-- -----------------------------------------------------------------------------
-- Table: profiles
-- Purpose: Stores public user profile information and application-specific user settings.
-- Complements Supabase's auth.users table.
-- -----------------------------------------------------------------------------
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE, -- References auth.users.id
    username TEXT UNIQUE NOT NULL CHECK (char_length(username) >= 3 AND char_length(username) <= 50), -- User-chosen display name
    avatar_url TEXT CHECK (avatar_url ~ '^https?://.'), -- URL to the user's avatar image
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL, -- Last update timestamp
    app_preferences JSONB -- User-specific application preferences (e.g., theme)
);

COMMENT ON TABLE public.profiles IS 'Stores public user profile information and application-specific user settings, linked to auth.users.';
COMMENT ON COLUMN public.profiles.id IS 'References auth.users.id. Primary key.';
COMMENT ON COLUMN public.profiles.username IS 'User-chosen, unique display name. Min 3, Max 50 characters.';
COMMENT ON COLUMN public.profiles.avatar_url IS 'URL to the user''s avatar image. Must be a valid HTTP(S) URL.';
COMMENT ON COLUMN public.profiles.updated_at IS 'Timestamp of the last profile update.';
COMMENT ON COLUMN public.profiles.app_preferences IS 'User-specific application preferences, stored as JSONB (e.g., {"theme": "dark", "notifications_enabled": true}).';

-- Enable Row Level Security for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles (Conceptual - Implement these in Supabase Dashboard or as separate SQL statements)
-- CREATE POLICY "Users can select their own profile." ON public.profiles FOR SELECT USING (auth.uid() = id);
-- CREATE POLICY "Users can update their own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
-- CREATE POLICY "Public can read specific profile fields." ON public.profiles FOR SELECT TO authenticated, anon USING (true); -- More granular control needed if only username/avatar are public


-- -----------------------------------------------------------------------------
-- Table: templates
-- Purpose: Stores predefined meme templates.
-- -----------------------------------------------------------------------------
CREATE TABLE public.templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique identifier
    name TEXT NOT NULL CHECK (char_length(name) > 0 AND char_length(name) <= 255), -- Name of the template
    description TEXT, -- Optional description
    image_url TEXT NOT NULL CHECK (image_url ~ '^https?://.'), -- URL to the template image in Supabase Storage
    thumbnail_url TEXT CHECK (thumbnail_url ~ '^https?://.'), -- URL to a smaller thumbnail of the template image
    tags TEXT[], -- Array of keywords for searching/filtering
    category TEXT CHECK (char_length(category) <= 100), -- Category of the template
    text_areas JSONB, -- Definition of editable text areas (e.g., [{"id": "top", "label": "Top Text", "defaultText": "Top"}])
    usage_count BIGINT DEFAULT 0 NOT NULL CHECK (usage_count >= 0), -- How many times this template has been used
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL, -- Creation timestamp
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL -- User who uploaded/created the template (e.g., admin)
);

COMMENT ON TABLE public.templates IS 'Stores predefined meme templates.';
COMMENT ON COLUMN public.templates.id IS 'Unique identifier for the template.';
COMMENT ON COLUMN public.templates.name IS 'Name of the template (max 255 characters).';
COMMENT ON COLUMN public.templates.description IS 'Optional description of the template.';
COMMENT ON COLUMN public.templates.image_url IS 'URL to the full-size template image, typically in Supabase Storage.';
COMMENT ON COLUMN public.templates.thumbnail_url IS 'URL to a smaller thumbnail of the template image.';
COMMENT ON COLUMN public.templates.tags IS 'Array of keywords for searching and filtering templates.';
COMMENT ON COLUMN public.templates.category IS 'Category of the template (e.g., "Reaction", "Animal"). Max 100 characters.';
COMMENT ON COLUMN public.templates.text_areas IS 'JSONB array defining editable text areas on the template. E.g., [{"id": "top", "label": "Top Text", "defaultText": "Top"}].';
COMMENT ON COLUMN public.templates.usage_count IS 'Counter for how many times this template has been used.';
COMMENT ON COLUMN public.templates.created_at IS 'Timestamp of when the template was created.';
COMMENT ON COLUMN public.templates.created_by IS 'Identifier of the user (admin) who created/uploaded the template. Nullable if system-generated or uploader unknown.';

-- Enable Row Level Security for templates
ALTER TABLE public.templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies for templates (Conceptual)
-- CREATE POLICY "Allow public read access for all users." ON public.templates FOR SELECT TO authenticated, anon USING (true);
-- CREATE POLICY "Restrict insert/update/delete to admin roles." ON public.templates FOR ALL USING (is_admin_user(auth.uid())) WITH CHECK (is_admin_user(auth.uid())); -- Requires an is_admin_user function


-- -----------------------------------------------------------------------------
-- Table: memes
-- Purpose: Stores user-generated and saved memes.
-- -----------------------------------------------------------------------------
CREATE TABLE public.memes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Unique identifier
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- The user who created/owns the meme
    template_id UUID REFERENCES public.templates(id) ON DELETE SET NULL, -- If created from a predefined template
    is_custom_image BOOLEAN NOT NULL DEFAULT false, -- True if the user uploaded their own image
    image_url TEXT NOT NULL CHECK (image_url ~ '^https?://.'), -- URL of the final meme image in Supabase Storage
    text_input JSONB, -- The text applied to the meme (e.g., {"top": "Hello", "bottom": "World"})
    analysis_results JSONB, -- Results from text analysis (tone, keywords). Nullable.
    tags TEXT[], -- User-defined or auto-generated tags
    visibility TEXT NOT NULL DEFAULT 'private' CHECK (visibility IN ('public', 'private', 'unlisted')), -- e.g., 'public', 'private', 'unlisted'
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL, -- Creation timestamp
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL -- Last update timestamp
);

COMMENT ON TABLE public.memes IS 'Stores user-generated and saved memes.';
COMMENT ON COLUMN public.memes.id IS 'Unique identifier for the meme.';
COMMENT ON COLUMN public.memes.user_id IS 'The user (from auth.users) who created/owns the meme. Cascade delete if user is deleted.';
COMMENT ON COLUMN public.memes.template_id IS 'The predefined template used, if any. Set to NULL if template is deleted.';
COMMENT ON COLUMN public.memes.is_custom_image IS 'True if the user uploaded their own image or heavily modified a template.';
COMMENT ON COLUMN public.memes.image_url IS 'URL of the final meme image, typically in Supabase Storage.';
COMMENT ON COLUMN public.memes.text_input IS 'JSONB object storing the text applied to the meme. E.g., {"top": "Hello", "bottom": "World"}.';
COMMENT ON COLUMN public.memes.analysis_results IS 'JSONB object storing results from text analysis (e.g., tone, keywords). Nullable.';
COMMENT ON COLUMN public.memes.tags IS 'Array of user-defined or auto-generated tags for the meme.';
COMMENT ON COLUMN public.memes.visibility IS 'Visibility setting for the meme: "public", "private", or "unlisted".';
COMMENT ON COLUMN public.memes.created_at IS 'Timestamp of when the meme was created.';
COMMENT ON COLUMN public.memes.updated_at IS 'Timestamp of the last meme update.';

-- Enable Row Level Security for memes
ALTER TABLE public.memes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for memes (Conceptual)
-- CREATE POLICY "Users can select their own memes." ON public.memes FOR SELECT USING (auth.uid() = user_id);
-- CREATE POLICY "Users can insert their own memes." ON public.memes FOR INSERT WITH CHECK (auth.uid() = user_id);
-- CREATE POLICY "Users can update their own memes." ON public.memes FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
-- CREATE POLICY "Users can delete their own memes." ON public.memes FOR DELETE USING (auth.uid() = user_id);
-- CREATE POLICY "Allow public read for public memes." ON public.memes FOR SELECT TO authenticated, anon USING (visibility = 'public');


-- -----------------------------------------------------------------------------
-- Helper function to automatically update updated_at columns
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to update updated_at timestamps
CREATE TRIGGER on_profiles_updated
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_memes_updated
BEFORE UPDATE ON public.memes
FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Note: Consider adding indexes for frequently queried columns, e.g.,
-- CREATE INDEX idx_templates_tags ON public.templates USING GIN (tags);
-- CREATE INDEX idx_memes_tags ON public.memes USING GIN (tags);
-- CREATE INDEX idx_memes_user_id_visibility ON public.memes (user_id, visibility);
-- CREATE INDEX idx_profiles_username ON public.profiles (username);
-- CREATE INDEX idx_templates_category ON public.templates (category);

-- Additional RLS considerations:
-- - An `is_admin_user` function would typically check against a separate table of admin user IDs or a custom claim in JWT.
-- - For `profiles` allowing public read of specific fields: this often requires a more complex policy or using a security barrier view.
--   A simpler approach for fully public profiles (if desired) is `USING (true)`, but the current spec implies more granular control.
-- - The `TO authenticated, anon` part in some conceptual RLS policies means it applies to both logged-in and anonymous users.
--   `TO authenticated` would apply only to logged-in users.
--   `TO public` is an alias for `TO authenticated, anon`.

-- End of Schema Definition
