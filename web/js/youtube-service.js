const YOUTUBE_API_KEY = 'AIzaSyCxp5wVexVBKWES_bxm1QfnZy10U71l6CU';
const CHANNEL_ID = 'UCH3GQ7cC1gvTSEbTSg2jW3Q';

async function getLatestSermon() {
    try {
        // Get channel uploads playlist ID
        const channelResponse = await fetch(
            `https://www.googleapis.com/youtube/v3/channels?part=contentDetails&id=${CHANNEL_ID}&key=${YOUTUBE_API_KEY}`
        );
        const channelData = await channelResponse.json();
        const uploadsPlaylistId = channelData.items[0].contentDetails.relatedPlaylists.uploads;

        // Get latest videos (increased to 50 to ensure we find a valid sermon)
        const videosResponse = await fetch(
            `https://www.googleapis.com/youtube/v3/playlistItems?part=snippet,contentDetails&playlistId=${uploadsPlaylistId}&maxResults=50&key=${YOUTUBE_API_KEY}`
        );
        const videosData = await videosResponse.json();

        // Get detailed video information for each video
        const videoIds = videosData.items.map(item => item.snippet.resourceId.videoId).join(',');
        const videoDetailsResponse = await fetch(
            `https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails,statistics&id=${videoIds}&key=${YOUTUBE_API_KEY}`
        );
        const videoDetailsData = await videoDetailsResponse.json();

        // Create a map of video details for easy lookup
        const videoDetailsMap = new Map(
            videoDetailsData.items.map(item => [item.id, item])
        );

        // Filter out unwanted videos
        const filteredVideos = videosData.items.filter(video => {
            const title = video.snippet.title.toLowerCase();
            const description = video.snippet.description.toLowerCase();
            const videoId = video.snippet.resourceId.videoId;
            const videoDetails = videoDetailsMap.get(videoId);
            
            if (!videoDetails) {
                console.log(`Skipping video ${videoId}: No video details available`);
                return false;
            }

            // Debug logging
            console.log(`Processing video: ${title}`);
            console.log(`Duration: ${videoDetails.contentDetails?.duration}`);
            
            // Multiple checks for YouTube Shorts:
            const isShort = (
                // 1. Check video duration (Shorts are 60 seconds or less)
                (videoDetails.contentDetails?.duration && 
                 parseDuration(videoDetails.contentDetails.duration) <= 60) ||
                
                // 2. Check aspect ratio (Shorts are vertical)
                video.snippet.thumbnails?.maxres?.height > video.snippet.thumbnails?.maxres?.width ||
                
                // 3. Check if standard thumbnail is missing (common for Shorts)
                !video.snippet.thumbnails?.standard ||
                
                // 4. Check for #shorts in title or description
                title.includes('#shorts') || description.includes('#shorts') ||
                
                // 5. Check URL pattern
                video.snippet.thumbnails?.default?.url?.includes('/shorts/')
            );

            if (isShort) {
                console.log(`Skipping video ${title}: Detected as Short`);
                return false;
            }
            
            // Exclude videos that contain these terms
            const excludeTerms = [
                'live',
                'livestream',
                'live-stream',
                'live stream',
                'worship service',
                'sabbath service',
                'church service',
                'divine service',
                'divine hour',
                '#shorts',
                'short',
                'reel',
                'clip',
                'teaser',
                'preview'
            ];
            
            // Check if any exclude terms are in the title or description
            const hasExcludedTerm = excludeTerms.some(term => 
                title.includes(term) || description.includes(term)
            );

            if (hasExcludedTerm) {
                console.log(`Skipping video ${title}: Contains excluded term`);
                return false;
            }
            
            // Return true only for videos that:
            // 1. Don't have excluded terms in title/description
            // 2. Aren't YouTube Shorts
            // 3. Have "sermon" or "message" in title/description (to ensure it's actually a sermon)
            const isSermon = title.includes('sermon') || 
                           description.includes('sermon') ||
                           title.includes('message') || 
                           description.includes('message');
            
            if (!isSermon) {
                console.log(`Skipping video ${title}: Not detected as sermon`);
                return false;
            }

            console.log(`Including video: ${title}`);
            return true;
        });

        // Get the first (latest) valid sermon
        const latestSermon = filteredVideos[0];
        
        if (!latestSermon) {
            throw new Error('No valid sermons found');
        }

        // Helper function to parse ISO 8601 duration to seconds
        function parseDuration(duration) {
            if (!duration) return 0;
            
            // Handle simple formats like "PT5M" or "PT2H"
            const matches = duration.match(/P(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?/);
            if (!matches) return 0;
            
            const [_, hours, minutes, seconds] = matches;
            return (parseInt(hours) || 0) * 3600 + 
                   (parseInt(minutes) || 0) * 60 + 
                   (parseInt(seconds) || 0);
        }

        // Format the date
        const publishDate = new Date(latestSermon.snippet.publishedAt);
        const formattedDate = publishDate.toLocaleDateString('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });

        return {
            title: latestSermon.snippet.title,
            description: latestSermon.snippet.description,
            videoId: latestSermon.snippet.resourceId.videoId,
            publishedAt: publishDate,
            formattedDate: formattedDate,
            thumbnails: latestSermon.snippet.thumbnails
        };
    } catch (error) {
        console.error('Error fetching YouTube data:', error);
        throw error;
    }
}

async function getUpcomingLivestream() {
    try {
        // Search for upcoming live streams
        const searchResponse = await fetch(
            `https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=${CHANNEL_ID}&eventType=upcoming&type=video&order=date&maxResults=1&key=${YOUTUBE_API_KEY}`
        );
        const searchData = await searchResponse.json();

        // If no upcoming streams found
        if (!searchData.items || searchData.items.length === 0) {
            return {
                found: false,
                message: "No upcoming live streams scheduled"
            };
        }

        const livestream = searchData.items[0];
        
        // Get more details about the video
        const videoResponse = await fetch(
            `https://www.googleapis.com/youtube/v3/videos?part=liveStreamingDetails,snippet&id=${livestream.id.videoId}&key=${YOUTUBE_API_KEY}`
        );
        const videoData = await videoResponse.json();
        const videoDetails = videoData.items[0];

        return {
            found: true,
            title: videoDetails.snippet.title,
            description: videoDetails.snippet.description,
            videoId: videoDetails.id,
            thumbnails: videoDetails.snippet.thumbnails,
            scheduledStartTime: new Date(videoDetails.liveStreamingDetails.scheduledStartTime),
            channelTitle: videoDetails.snippet.channelTitle
        };
    } catch (error) {
        console.error('Error fetching upcoming livestream:', error);
        throw error;
    }
}

export { getLatestSermon, getUpcomingLivestream }; 