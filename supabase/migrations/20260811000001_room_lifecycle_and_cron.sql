-- 1. Create function to clean up inactive waiting rooms (older than 10 mins) and finish expired games
CREATE OR REPLACE FUNCTION public.process_rooms_and_games_cron()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Delete inactive WAITING rooms older than 10 minutes
    DELETE FROM public.rooms 
    WHERE status = 'WAITING' 
      AND created_at < NOW() - INTERVAL '10 minutes';

    -- Force end ongoing games whose deadline has passed
    UPDATE public.rooms
    SET status = 'ENDED'
    WHERE status = 'ONGOING'
      AND game_end_time IS NOT NULL
      AND game_end_time <= NOW();
END;
$$;

-- 2. Schedule pg_cron job to execute every 10 minutes
SELECT cron.unschedule('process_rooms_and_games_cron_job') 
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'process_rooms_and_games_cron_job');

SELECT cron.schedule(
    'process_rooms_and_games_cron_job',
    '*/10 * * * *',
    'SELECT public.process_rooms_and_games_cron();'
);

-- 3. Run immediate cleanup
DELETE FROM public.rooms 
WHERE status = 'WAITING' 
  AND created_at < NOW() - INTERVAL '10 minutes';
