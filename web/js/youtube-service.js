import { getValue, initializeFirebase } from './firebase-config.js';
import { getRemoteConfig } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-remote-config.js";
import { getEnvVar } from './env-config.js';

const CHANNEL_ID = 'UCH3GQ7cC1gvTSEbTSg2jW3Q';  // Fixed channel ID
const isDevelopment = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';

// Cache configuration
const CACHE_DURATION = {
    SERMON: 24 * 60 * 60 * 1000,     // 24 hours for sermons
    LIVESTREAM: 5 * 60 * 1000   // 5 minutes for livestreams
};

// Singleton instance
let instance = null;

class YouTubeService {
    constructor() {
        if (instance) {
            return instance;
        }

        // Initialize Firebase first
        initializeFirebase().catch(error => {
            console.error('Failed to initialize Firebase:', error);
        });
        
        // Try to load cache from localStorage
        try {
            const savedCache = localStorage.getItem('youtubeCache');
            const savedLastFetch = localStorage.getItem('youtubeLastFetch');
            
            if (savedCache && savedLastFetch) {
                this.cache = JSON.parse(savedCache);
                this.lastFetch = JSON.parse(savedLastFetch);
                console.log('Loaded cache from localStorage:', {
                    cache: this.cache,
                    lastFetch: this.lastFetch
                });
            } else {
                this.cache = {
                    sermon: null,
                    livestream: null
                };
                this.lastFetch = {
                    sermon: 0,
                    livestream: 0
                };
                console.log('Initialized new cache');
            }
        } catch (error) {
            console.warn('Error loading cache from localStorage:', error);
            this.cache = {
                sermon: null,
                livestream: null
            };
            this.lastFetch = {
                sermon: 0,
                livestream: 0
            };
        }
        
        instance = this;
        return instance;
    }

    static getInstance() {
        if (!instance) {
            instance = new YouTubeService();
        }
        return instance;
    }

    isCacheValid(type) {
        const now = Date.now();
        const lastFetch = this.lastFetch[type];
        
        // If there's no lastFetch timestamp, cache is invalid
        if (!lastFetch) {
            console.log(`Cache ${type} invalid: no previous fetch`);
            return false;
        }
        
        const ageInMs = now - lastFetch;
        const ageInSeconds = Math.floor(ageInMs / 1000);
        const ageInMinutes = Math.floor(ageInSeconds / 60);
        const ageInHours = Math.floor(ageInMinutes / 60);
        const ageInDays = Math.floor(ageInHours / 24);
        
        let ageString;
        if (ageInDays > 0) {
            ageString = `${ageInDays} days`;
        } else if (ageInHours > 0) {
            ageString = `${ageInHours} hours`;
        } else if (ageInMinutes > 0) {
            ageString = `${ageInMinutes} minutes`;
        } else {
            ageString = `${ageInSeconds} seconds`;
        }
        
        const isValid = ageInMs < CACHE_DURATION[type.toUpperCase()];
        console.log(`Cache ${type} ${isValid ? 'valid' : 'invalid'}: age ${ageString}`);
        return isValid;
    }

    // Function to convert YouTube duration to minutes
    getDurationInMinutes(duration) {
        if (!duration) return 0;
        
        try {
            // YouTube duration format: PT#H#M#S
            const match = duration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
            if (!match) {
                console.warn('Invalid duration format:', duration);
                return 0;
            }
            
            const hours = parseInt(match[1] || '0', 10);
            const minutes = parseInt(match[2] || '0', 10);
            const seconds = parseInt(match[3] || '0', 10);
            
            const totalMinutes = (hours * 60) + minutes + (seconds / 60);
            console.log(`Duration parsed: ${duration} -> ${totalMinutes} minutes`);
            return totalMinutes;
        } catch (error) {
            console.error('Error parsing duration:', duration, error);
            return 0;
        }
    }

    async getLatestSermon() {
        // Check cache first
        if (this.isCacheValid('sermon') && this.cache.sermon) {
            console.log('Using cached sermon data');
            return this.cache.sermon;
        }

        console.log('Fetching latest sermon...');
        
        try {
            let apiKey;
            
            if (isDevelopment) {
                // In development, get the API key from env-config
                apiKey = getEnvVar('YOUTUBE_API_KEY');
                if (apiKey) {
                    console.log('Using YouTube API key from env-config');
                }
            }
            
            // If we didn't get the key from env-config, try Remote Config
            if (!apiKey) {
                apiKey = getValue(getRemoteConfig(), 'youtube_api_key');
            }

            if (!apiKey) {
                console.error('YouTube API key not available');
                return {
                    title: 'Latest Sermon',
                    description: 'Unable to fetch latest sermon at this time.',
                    videoId: null,
                    error: 'API key not available'
                };
            }

            // First get a list of recent videos
            const searchUrl = `https://www.googleapis.com/youtube/v3/search?key=${apiKey}&channelId=${CHANNEL_ID}&part=snippet&order=date&maxResults=50&type=video`;
            const searchResponse = await fetch(searchUrl);
            
            if (!searchResponse.ok) {
                const error = await searchResponse.json();
                console.error('YouTube API error:', error);
                return {
                    title: 'Latest Sermon',
                    description: 'Unable to fetch latest sermon at this time.',
                    videoId: null,
                    error: error.error ? error.error.message : 'Unknown error'
                };
            }

            const searchData = await searchResponse.json();
            
            if (!searchData.items || searchData.items.length === 0) {
                console.warn('No videos found');
                return {
                    title: 'Latest Sermon',
                    description: 'No recent sermons found.',
                    videoId: null,
                    error: 'No videos found'
                };
            }

            // Get video IDs
            const videoIds = searchData.items.map(item => item.id.videoId).join(',');

            // Get detailed video information including duration
            const videosUrl = `https://www.googleapis.com/youtube/v3/videos?key=${apiKey}&id=${videoIds}&part=snippet,contentDetails`;
            const videosResponse = await fetch(videosUrl);
            const videosData = await videosResponse.json();

            // Find all videos that match sermon criteria
            const sermons = videosData.items
                .map(video => {
                    try {
                        const title = video.snippet.title.toLowerCase();
                        const description = video.snippet.description.toLowerCase();
                        const duration = this.getDurationInMinutes(video.contentDetails?.duration);
                        const publishedAt = new Date(video.snippet.publishedAt);
                        
                        // Check if it's not a short (longer than 15 minutes)
                        const isLongEnough = duration >= 15;
                        
                        // Check if it's NOT a worship service
                        const serviceKeywords = ['worship service', 'sabbath service', 'divine service', 'church service'];
                        const isNotWorshipService = !serviceKeywords.some(keyword => 
                            title.includes(keyword)
                        );
                        
                        // Check if it's not a livestream
                        const notLivestream = video.snippet.liveBroadcastContent === 'none';
                        
                        // Look for sermon keywords or check if it's a sermon based on duration
                        const sermonKeywords = ['sermon', 'message', 'preaching'];
                        const hasSermonKeywords = sermonKeywords.some(keyword =>
                            title.includes(keyword) ||
                            description.includes(keyword)
                        );
                        
                        // Consider it a sermon if it has keywords or is long enough and not a service
                        const isSermon = hasSermonKeywords || (isLongEnough && isNotWorshipService);
                        
                        // Log decision factors
                        console.log('Video analysis:', {
                            title,
                            publishedAt: publishedAt.toISOString(),
                            duration,
                            isLongEnough,
                            isNotWorshipService,
                            hasSermonKeywords,
                            isSermon,
                            notLivestream
                        });
                        
                        if (isSermon && notLivestream) {
                            return {
                                video,
                                publishedAt,
                                duration
                            };
                        }
                        return null;
                    } catch (error) {
                        console.error('Error processing video:', video, error);
                        return null;
                    }
                })
                .filter(Boolean)
                .sort((a, b) => b.publishedAt - a.publishedAt);

            console.log('Found sermons:', sermons.map(s => ({
                title: s.video.snippet.title,
                publishedAt: s.publishedAt.toISOString(),
                duration: s.duration,
                id: s.video.id
            })));

            if (sermons.length === 0) {
                console.warn('No sermons found in recent videos');
                return {
                    title: 'Latest Sermon',
                    description: 'No recent sermons found.',
                    videoId: null,
                    error: 'No sermons found'
                };
            }

            // Use the most recent sermon
            const sermon = sermons[0].video;

            const latestSermon = {
                title: sermon.snippet.title,
                description: sermon.snippet.description,
                videoId: sermon.id,
                thumbnail: sermon.snippet.thumbnails.high.url
            };

            // Update cache and timestamp
            this.cache.sermon = latestSermon;
            this.lastFetch.sermon = Date.now();
            this.saveCache();
            return latestSermon;
        } catch (error) {
            console.error('Error fetching sermon:', error);
            return {
                title: 'Latest Sermon',
                description: 'Unable to fetch latest sermon at this time.',
                videoId: null,
                error: error.message
            };
        }
    }

    async getUpcomingLivestream() {
        // Check cache first
        if (this.isCacheValid('livestream') && this.cache.livestream) {
            console.log('Using cached livestream data');
            return this.cache.livestream;
        }

        try {
            let apiKey;
            
            if (isDevelopment) {
                // In development, get the API key from env-config
                apiKey = getEnvVar('YOUTUBE_API_KEY');
                if (apiKey) {
                    console.log('Using YouTube API key from env-config');
                }
            }
            
            // If we didn't get the key from env-config, try Remote Config
            if (!apiKey) {
                apiKey = getValue(getRemoteConfig(), 'youtube_api_key');
            }

            if (!apiKey) {
                console.error('YouTube API key not available');
                return {
                    title: 'Upcoming Livestream',
                    description: 'Unable to fetch livestream at this time.',
                    videoId: null,
                    error: 'API key not available'
                };
            }

            console.log('Using YouTube API key:', apiKey.substring(0, 8) + '...');
            const searchUrl = `https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=${CHANNEL_ID}&eventType=upcoming&type=video&key=${apiKey}&order=date`;
            console.log('Fetching from URL:', searchUrl);
            
            const response = await fetch(searchUrl);
            console.log('Response status:', response.status);
            
            if (!response.ok) {
                const error = await response.json();
                console.error('YouTube API error:', error);
                return {
                    title: 'Upcoming Livestream',
                    description: 'Unable to fetch livestream at this time.',
                    videoId: null,
                    error: error.error ? error.error.message : 'Unknown error'
                };
            }

            const data = await response.json();
            console.log('YouTube API response:', data);

            if (!data.items || data.items.length === 0) {
                console.log('No upcoming livestreams found');
                return {
                    title: 'Upcoming Livestream',
                    description: 'No upcoming livestreams scheduled.',
                    videoId: null,
                    error: 'No livestreams found'
                };
            }

            const livestream = data.items[0];
            console.log('Upcoming livestream:', livestream);

            const livestreamData = {
                title: livestream.snippet.title || 'Upcoming Livestream',
                description: livestream.snippet.description || '',
                videoId: livestream.id.videoId,
                thumbnail: livestream.snippet.thumbnails?.high?.url || livestream.snippet.thumbnails?.default?.url
            };

            // Update cache
            this.cache.livestream = livestreamData;
            this.lastFetch.livestream = Date.now();
            this.saveCache();

            return livestreamData;
        } catch (error) {
            console.error('Error fetching upcoming livestream:', error);
            return {
                title: 'Upcoming Livestream',
                description: 'Unable to fetch livestream at this time.',
                videoId: null,
                error: error.message
            };
        }
    }

    // Helper method to save cache to localStorage
    saveCache() {
        try {
            localStorage.setItem('youtubeCache', JSON.stringify(this.cache));
            localStorage.setItem('youtubeLastFetch', JSON.stringify(this.lastFetch));
            console.log('Saved cache to localStorage');
        } catch (error) {
            console.warn('Error saving cache to localStorage:', error);
        }
    }
}

export default YouTubeService;