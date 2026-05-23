-- Allow any MIME type in the audio bucket (CLI uploads as application/octet-stream)
UPDATE storage.buckets
SET allowed_mime_types = NULL
WHERE id = 'audio';
