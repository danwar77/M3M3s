# Supabase Edge Functions Plan for Custom Meme Logic

## 1. Introduction

Supabase Edge Functions provide a way to run server-side TypeScript code (Deno runtime) in response to HTTP requests or other Supabase events. For our meme generation application, Edge Functions are ideal for implementing custom backend logic that goes beyond simple CRUD operations, such as integrating with third-party AI/NLP services, performing complex calculations, or orchestrating data between services.

This document outlines the plan for using Edge Functions to handle advanced features like text analysis, template suggestions, and potentially AI image generation.

## 2. Identified Custom Logic Requirements

The core custom server-side logic components identified for the meme application are:

*   **Text Analysis (NLP):**
    *   Extracting emotional tone (e.g., humorous, serious, sarcastic) from user-provided text.
    *   Identifying key entities, keywords, and topics.
    *   Detecting the language of the input text.
    *   This information is crucial for suggesting relevant templates or even guiding AI image generation.

*   **Template Recommendation/Selection:**
    *   Based on the results of text analysis, suggest or automatically select appropriate meme templates.
    *   This could involve:
        *   Matching keywords from text analysis with tags or descriptions of templates stored in the Supabase database.
        *   More advanced AI-driven semantic matching between user text and template themes/content.

*   **AI Image Generation (Optional Feature):**
    *   If the application supports generating meme images from scratch based on textual prompts, this would involve integrating with an external AI image generation service.

*   **Server-Side Image Manipulation (Consideration):**
    *   While powerful image manipulation (e.g., rendering text with custom fonts directly onto complex images) can be resource-intensive for standard Edge Functions, basic operations or orchestrating calls to specialized image services might be considered.
    *   For this plan, we will assume text rendering onto templates primarily happens client-side or via a dedicated image generation service if AI image generation is used.

## 3. Proposed Supabase Edge Functions

We propose the following Edge Functions to encapsulate the custom logic:

### 3.1. Function: `get-meme-suggestions`

*   **Purpose:**
    Analyzes the user's input text using an NLP service and suggests relevant meme templates from the database, along with extracted text insights.
*   **Input (JSON):**
    The function will expect a JSON payload with the following structure:
    json
    {
      "text": "User's input phrase for the meme",
      "userId": "optional_user_id_for_personalization_or_logging"
    }
    
*   **Output (JSON):**
    The function will return a JSON response with analyzed text and template suggestions:
    json
    {
      "analyzedText": {
        "original": "User's input phrase",
        "tone": "humorous", // e.g., from NLP service
        "keywords": ["keyword1", "keyword2", "funny"], // from NLP service
        "language": "en" // from NLP service
      },
      "suggestedTemplates": [ // Query results from 'templates' table based on keywords/tone
        { 
          "templateId": "uuid-template-1", 
          "name": "Drake Hotline Bling", 
          "imageUrl": "url/to/template1.jpg",
          "matchScore": 0.85 // Calculated relevance score
        },
        { 
          "templateId": "uuid-template-2", 
          "name": "Distracted Boyfriend", 
          "imageUrl": "url/to/template2.jpg",
          "matchScore": 0.72
        }
      ],
      "suggestedTextPlacement": { // Optional, if backend logic can intelligently suggest text split
        "top": "Suggested Top Text based on analysis",
        "bottom": "Suggested Bottom Text"
      }
    }
    
*   **Internal Logic:**
    1.  **Input Validation:** Validate the incoming `text` field.
    2.  **NLP Integration:**
        *   Make an HTTP request (`fetch`) to an external NLP API (e.g., Google Natural Language API, Cohere, OpenAI's completion/analysis endpoints).
        *   The API key for the NLP service will be stored as a Supabase secret (`supabase secrets set NLP_API_KEY=your_key_value`).
        *   Extract tone, keywords, and language from the NLP response.
    3.  **Template Querying:**
        *   Initialize a Supabase client within the Edge Function.
        *   Construct a query to the `templates` table in the Supabase database.
        *   Filter templates based on `keywords` (matching against `templates.tags` or `templates.name`, `templates.description`) and potentially `tone` (if templates are tagged with mood).
        *   Implement a basic ranking/scoring algorithm for template suggestions (e.g., number of keyword matches, popularity of template).
    4.  **Text Placement Suggestion (Optional):**
        *   Implement simple logic to split the input text or suggest placement if the analysis provides enough context (e.g., if the text is a question/answer pair).
    5.  **Error Handling:** Wrap external API calls and database queries in try-catch blocks. Return appropriate error responses if any step fails.

### 3.2. Function: `generate-ai-image` (If AI Image Generation is a Feature)

*   **Purpose:**
    Generates a novel image using an external AI image generation service based on a user-provided prompt.
*   **Input (JSON):**
    json
    {
      "prompt": "Detailed textual prompt for the AI image generation",
      "userId": "user_id_for_tracking_logging_or_applying_quotas",
      "outputStyle": "e.g., photorealistic, cartoon, pixel_art", // Optional
      "aspectRatio": "e.g., 1:1, 16:9" // Optional
    }
    
*   **Output (JSON):**
    json
    {
      "imageUrl": "url_to_the_generated_image", // This could be a direct URL from the AI service or a URL from Supabase Storage after uploading
      "storagePath": "optional_path_if_uploaded_to_supabase_storage", // e.g., "user_id/ai_generated/image_uuid.png"
      "serviceUsed": "Name of the AI image generation service (e.g., DALL-E, Stability AI)",
      "promptUsed": "The actual prompt sent to the AI service (might be modified/enhanced by the Edge Function)"
    }
    
*   **Internal Logic:**
    1.  **Input Validation:** Validate the `prompt`.
    2.  **Prompt Engineering (Optional):** Enhance or modify the user's prompt for better results with the chosen AI service.
    3.  **AI Service Integration:**
        *   Make an HTTP request (`fetch`) to an external AI image generation API (e.g., OpenAI DALL-E API, Stability AI API, or other services like Replicate).
        *   The API key for the AI service will be stored as a Supabase secret.
    4.  **Image Handling:**
        *   The AI service might return an image URL directly or image data (e.g., base64).
        *   If image data is returned, the Edge Function could upload it to a designated private bucket (e.g., `user_memes` under `[USER_ID]/ai_generated/`) in Supabase Storage.
        *   The public URL (or a signed URL if the bucket is private and direct access is needed) for the image in Supabase Storage would then be returned.
    5.  **Logging/Tracking:** Record generation requests, user ID, and service usage for analytics or quota management (e.g., in a dedicated database table).
    6.  **Error Handling:** Manage errors from the AI service (e.g., content policy violations, service unavailability) and return appropriate error responses.

## 4. Data Flow with Flutter App

1.  **Input:** Flutter app collects user's text for the meme.
2.  **Invoke `get-meme-suggestions`:**
    *   Flutter app calls `Supabase.instance.client.functions.invoke('get-meme-suggestions', body: {'text': userInput, 'userId': currentUserId});`.
3.  **Receive Suggestions:** The Flutter app receives the JSON response containing `analyzedText`, `suggestedTemplates`, etc.
4.  **User/App Action:**
    *   The app displays suggested templates or uses the analysis to narrow down choices.
    *   The user might select a template, or the app might automatically pick the top suggestion.
5.  **Meme Creation (Client-Side Rendering Focus):**
    *   **Template Image:** Flutter app fetches the selected template's `imageUrl` (which points to Supabase Storage, likely a public URL for templates).
    *   **Text Placement:** The app uses `analyzedText.original` (or `suggestedTextPlacement`) and allows the user to place/edit text on the template image using client-side Flutter widgets (e.g., `Stack`, `Positioned`, `TextEditor`).
    *   The final meme is rendered as a widget or captured as an image on the client.
6.  **Meme Creation (AI Image Generation Focus - if feature is active):**
    *   **Invoke `generate-ai-image`:** If the user opts for AI image generation, the Flutter app constructs a prompt (possibly guided by `analyzedText`) and calls `Supabase.instance.client.functions.invoke('generate-ai-image', body: {'prompt': imagePrompt, 'userId': currentUserId});`.
    *   **Receive Image:** The app receives the `imageUrl` of the AI-generated image.
    *   **Text Placement (if applicable):** Text can then be overlaid on this AI-generated image client-side.
7.  **Display & Save:**
    *   The Flutter app displays the final composed/generated meme.
    *   If the user chooses to save, the client-rendered image (as `Uint8List`) or the URL of the AI-generated image (if stored in Supabase Storage by the Edge Function) is then used in the `POST /api/v1/memes` request (defined in `openapi.yaml`). The `imageUrl` field in the `MemeSaveRequest` would point to the new image in Supabase Storage (uploaded by the client after rendering, or directly by the `generate-ai-image` function).

## 5. Technology and Implementation Details

*   **Language:** **TypeScript** (Deno runtime, as provided by Supabase Edge Functions).
*   **Supabase Client (`@supabase/supabase-js`):**
    *   Use `createClient` from `@supabase/supabase-js` within Edge Functions to interact with the Supabase database (e.g., for querying templates) or Storage (if functions need to manage files directly).
    *   The service role key might be needed for certain privileged operations if user context isn't directly passed or applicable, but it's generally better to use the user's JWT if possible by forwarding it or using the client initialized with auth context. For simplicity and security, Supabase client in Edge Functions can be initialized with `SUPABASE_SERVICE_ROLE_KEY` for backend operations like querying the templates table.
*   **External APIs (`fetch`):**
    *   Standard `fetch` API will be used for making HTTPS requests to external NLP and AI image generation services.
*   **Secrets Management:**
    *   API keys for external services (NLP, AI Image Gen) **MUST** be stored as Supabase Edge Function secrets:
        bash
        supabase secrets set NLP_API_KEY=your_nlp_api_key_value
        supabase secrets set AI_IMAGE_API_KEY=your_ai_image_api_key_value
        
    *   Access these in the function code via `Deno.env.get('NLP_API_KEY')`.
*   **Error Handling:**
    *   Implement robust `try...catch` blocks for all external API calls and database interactions.
    *   Return clear JSON error responses with appropriate HTTP status codes (e.g., 500 for internal server errors, 400 for bad input, 503 for service unavailable if an external API fails).
*   **CORS Headers:**
    *   When invoking functions via `supabase_flutter`'s `functions.invoke()`, CORS is generally handled.
    *   If you intend to call these functions from a web browser directly (not through the Supabase JS client), ensure your function explicitly returns the necessary CORS headers (e.g., `Access-Control-Allow-Origin: *`). Supabase Functions have built-in options for this.
*   **Local Development and Testing:**
    *   Use the Supabase CLI to develop and test Edge Functions locally: `supabase functions serve --no-verify-jwt`.

## 6. Limitations and Alternatives

*   **Execution Limits:**
    *   Supabase Edge Functions have execution time limits (typically 1-10 seconds, region-dependent), memory limits (e.g., 128-512MB), and deployment bundle size limits.
    *   Very complex NLP models or on-the-fly AI model inference directly within the function are not feasible. Rely on external APIs for these.
    *   Long-running tasks (e.g., waiting for a slow AI image generation) might hit timeouts. Consider asynchronous patterns if direct responses take too long (e.g., webhook callbacks, or client polls for results – though this adds complexity).
*   **Cold Starts:** Edge Functions can have cold starts, which might add latency to the first request. This is common in serverless environments.
*   **Heavy Dependencies:** Native Node.js libraries or large Python AI/ML models cannot be directly bundled or run. The Deno runtime supports TypeScript/JavaScript and WASM.
*   **Alternative - Dedicated Microservice:**
    *   If the custom logic becomes exceedingly complex, requires specific runtime environments not supported by Deno (e.g., Python for specific ML libraries), or has resource demands exceeding Edge Function limits, a dedicated microservice is a viable alternative.
    *   This microservice could be built with Python (Flask/FastAPI), Node.js (Express), etc., and hosted on platforms like Google Cloud Run, AWS Lambda (with a container), or Heroku.
    *   The Flutter app could call this microservice directly, or an Edge Function could act as a lightweight proxy/gateway to it, which can help keep a unified API front through Supabase. The OpenAPI specification might then be partially implemented by this external microservice.

This plan provides a roadmap for leveraging Supabase Edge Functions to enhance the meme application with intelligent features, while also acknowledging their limitations and considering alternatives for more demanding scenarios.

