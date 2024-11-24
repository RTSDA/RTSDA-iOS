// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js";
import { getFirestore, collection, query, orderBy, onSnapshot, doc, updateDoc, deleteDoc, addDoc, serverTimestamp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";
import { getRemoteConfig, fetchAndActivate, getValue as getRemoteConfigValue } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-remote-config.js";
import { getEnvVar } from './env-config.js';

// Check if we're running in development mode
const isDevelopment = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';

// Your web app's Firebase configuration
const firebaseConfig = {
    apiKey: getEnvVar('FIREBASE_API_KEY'),
    authDomain: getEnvVar('FIREBASE_AUTH_DOMAIN'),
    projectId: getEnvVar('FIREBASE_PROJECT_ID'),
    storageBucket: getEnvVar('FIREBASE_STORAGE_BUCKET'),
    messagingSenderId: getEnvVar('FIREBASE_MESSAGING_SENDER_ID'),
    appId: getEnvVar('FIREBASE_APP_ID'),
    measurementId: getEnvVar('FIREBASE_MEASUREMENT_ID')
};

let app;
let db;
let auth;
let remoteConfig;
let configInitialized = false;
let cachedConfig = {};

// Load environment variables
async function loadEnvVariables() {
    try {
        const response = await fetch('/.env');
        const text = await response.text();
        const env = {};
        text.split('\n').forEach(line => {
            const [key, value] = line.split('=');
            if (key && value) {
                env[key.trim()] = value.trim();
            }
        });
        return env;
    } catch (error) {
        console.warn('Could not load .env file:', error);
        return {};
    }
}

// Initialize Firebase and all services
async function initializeFirebase() {
    try {
        app = initializeApp(firebaseConfig);
        console.log('Firebase initialized successfully');
        
        db = getFirestore(app);
        auth = getAuth(app);
        
        // In development, always use env-config.js
        if (isDevelopment) {
            const envApiKey = getEnvVar('YOUTUBE_API_KEY');
            if (envApiKey) {
                cachedConfig['youtube_api_key'] = envApiKey;
                console.log('Development mode: Using YouTube API key from env-config.js');
            } else {
                console.warn('Development mode: No YouTube API key found in env-config.js');
            }
            configInitialized = true;
            return true;
        }
        
        // Production: Use Remote Config
        remoteConfig = getRemoteConfig(app);
        remoteConfig.settings = {
            minimumFetchIntervalMillis: 3600000, // 1 hour
            fetchTimeoutMillis: 60000 // 1 minute
        };
        
        try {
            await fetchAndActivate(remoteConfig);
            console.log('Remote Config activated');
            
            const youtubeApiKey = getRemoteConfigValue(remoteConfig, 'youtube_api_key');
            if (youtubeApiKey) {
                cachedConfig['youtube_api_key'] = youtubeApiKey.asString();
                const prefix = cachedConfig['youtube_api_key'].substring(0, 8);
                console.log(`Successfully fetched YouTube API key from Remote Config (prefix: ${prefix}...)`);
            } else {
                console.warn('No YouTube API key found in Remote Config');
            }
        } catch (configError) {
            console.error('Error with Remote Config:', configError);
        }
        
        configInitialized = true;
        return true;
    } catch (error) {
        console.error('Error initializing Firebase:', error);
        throw error;
    }
}

// Helper function to get Remote Config values
function getValue(remoteConfig, key) {
    // For YouTube API key, always return from cache if available
    if (key === 'youtube_api_key' && cachedConfig[key]) {
        return cachedConfig[key];
    }
    
    try {
        const value = getRemoteConfigValue(remoteConfig, key);
        if (value) {
            const stringValue = value.asString();
            cachedConfig[key] = stringValue;
            return stringValue;
        }
    } catch (error) {
        console.error('Error getting Remote Config value:', error);
        // For YouTube API key in development, return from .env
        if (key === 'youtube_api_key' && isDevelopment) {
            return cachedConfig[key];
        }
    }
    return null;
}

// Create a service class to match Android implementation
class PrayerRequestService {
    constructor() {
        if (!db) throw new Error('Firebase must be initialized before using PrayerRequestService');
        this.collection = collection(db, "prayerRequests");
    }

    async submitRequest(request) {
        try {
            const prayerRequest = {
                name: request.name,
                email: request.email || '',
                phone: request.phone || '',
                request: request.request,
                timestamp: serverTimestamp(),
                status: 'new',
                isPrivate: request.isPrivate || false,
                requestType: request.requestType || 'Personal'
            };
            
            const docRef = await addDoc(this.collection, prayerRequest);
            return true;
        } catch (e) {
            console.error("Error submitting prayer request:", e);
            return false;
        }
    }

    subscribeToRequests(callback) {
        const q = query(this.collection, orderBy("timestamp", "desc"));
        return onSnapshot(q, (snapshot) => {
            const requests = [];
            snapshot.forEach((doc) => {
                requests.push({ id: doc.id, ...doc.data() });
            });
            callback(requests);
        });
    }

    async updateRequestStatus(requestId, newStatus) {
        try {
            await updateDoc(doc(db, 'prayerRequests', requestId), {
                status: newStatus
            });
            return true;
        } catch (e) {
            console.error("Error updating prayer request status:", e);
            return false;
        }
    }

    async deleteRequest(requestId) {
        try {
            await deleteDoc(doc(db, 'prayerRequests', requestId));
            return true;
        } catch (e) {
            console.error("Error deleting prayer request:", e);
            return false;
        }
    }
}

export { initializeFirebase, db, auth, PrayerRequestService, getValue, getRemoteConfig, firebaseConfig };