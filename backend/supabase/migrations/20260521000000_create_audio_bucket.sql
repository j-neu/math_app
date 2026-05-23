-- Create public audio bucket for diagnostic audio assets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'audio',
  'audio',
  true,
  10485760, -- 10 MB
  ARRAY['audio/mpeg', 'audio/mp3', 'audio/ogg', 'audio/wav']
)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Allow anyone to read audio files (public bucket)
CREATE POLICY "Public audio read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'audio');
