-- Add title column to rooms table
ALTER TABLE public.rooms 
ADD COLUMN IF NOT EXISTS title VARCHAR(50) DEFAULT '마니또 작전 대기실';
