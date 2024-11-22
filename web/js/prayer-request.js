// Import Firebase modules
import { serverTimestamp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';
import { PrayerRequestService } from './firebase-config.js';

// Initialize the prayer request service
const prayerRequestService = new PrayerRequestService();

document.addEventListener('DOMContentLoaded', async function() {
    const form = document.getElementById('prayerRequestForm');
    
    if (!form) {
        console.error('Prayer request form not found');
        return;
    }

    // Add input validation on phone field while typing
    const phoneInput = form.phone;
    if (phoneInput) {
        phoneInput.addEventListener('input', function(e) {
            const value = e.target.value.replace(/\D/g, ''); // Remove non-digits
            if (value.length <= 10) {
                // Format as (XXX) XXX-XXXX
                if (value.length > 6) {
                    e.target.value = `(${value.slice(0,3)}) ${value.slice(3,6)}-${value.slice(6)}`;
                } else if (value.length > 3) {
                    e.target.value = `(${value.slice(0,3)}) ${value.slice(3)}`;
                } else if (value.length > 0) {
                    e.target.value = `(${value}`;
                }
            } else {
                e.target.value = e.target.value.slice(0, 14); // Limit to (XXX) XXX-XXXX
            }
        });
    }
    
    function validateEmail(email) {
        return email === '' || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

    function validatePhone(phone) {
        return phone === '' || /^\(\d{3}\) \d{3}-\d{4}$/.test(phone);
    }

    function validateName(name) {
        return name.length >= 2 && name.length <= 100;
    }

    function validateRequest(request) {
        return request.length >= 10 && request.length <= 1000;
    }
    
    form.addEventListener('submit', async function(e) {
        e.preventDefault();
        
        // Disable submit button to prevent double submission
        const submitButton = form.querySelector('button[type="submit"]');
        if (submitButton) {
            submitButton.disabled = true;
        }
        
        try {
            // Get form values
            const name = form.name.value.trim();
            const email = form.email.value.trim();
            const phone = form.phone.value.trim();
            const message = form.message.value.trim();
            
            // Validate all fields
            const errors = [];
            
            if (!validateName(name)) {
                errors.push('Name must be between 2 and 100 characters');
            }
            
            if (!validateEmail(email)) {
                errors.push('Please enter a valid email address or leave it empty');
            }
            
            if (!validatePhone(phone)) {
                errors.push('Please enter a valid phone number in format (XXX) XXX-XXXX or leave it empty');
            }
            
            if (!validateRequest(message)) {
                errors.push('Prayer request must be between 10 and 1000 characters');
            }
            
            if (errors.length > 0) {
                throw new Error(errors.join('\n'));
            }

            // Create prayer request document matching Android model
            const prayerRequest = {
                name: name,
                email: email,
                phone: phone,
                request: message,
                timestamp: serverTimestamp(),
                status: 'new',
                isPrivate: form.isPrivate ? form.isPrivate.checked : false
            };
            
            // Submit using the service
            const success = await prayerRequestService.submitRequest(prayerRequest);
            
            if (!success) {
                throw new Error('Failed to submit prayer request');
            }
            
            // Clear form
            form.reset();
            
            // Show success message
            alert('Your prayer request has been submitted. We will be praying for you.');
            
            // Redirect to thank you page
            window.location.href = 'thankyou.html';
            
        } catch (error) {
            console.error('Error submitting prayer request:', error);
            alert(error.message || 'There was an error submitting your prayer request. Please try again.');
        } finally {
            // Re-enable submit button
            if (submitButton) {
                submitButton.disabled = false;
            }
        }
    });
});
