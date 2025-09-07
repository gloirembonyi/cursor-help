// 📚 Cursor Helper - Help Page JavaScript
class HelpPageApp {
    constructor() {
        this.init();
    }

    init() {
        this.setupScrollSpyNavigation();
        this.setupSmoothScrolling();
        this.setupAnimations();
        this.setupCopyCodeElements();
        this.addInteractiveElements();
    }

    // Setup scroll spy navigation
    setupScrollSpyNavigation() {
        const tocItems = document.querySelectorAll('.toc-item');
        const sections = document.querySelectorAll('.content-section');
        
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const id = entry.target.id;
                    tocItems.forEach(item => {
                        item.classList.remove('active');
                        if (item.getAttribute('href') === `#${id}`) {
                            item.classList.add('active');
                        }
                    });
                }
            });
        }, {
            rootMargin: '-20% 0px -70% 0px',
            threshold: 0.1
        });

        sections.forEach(section => {
            observer.observe(section);
        });
    }

    // Setup smooth scrolling for anchor links
    setupSmoothScrolling() {
        const anchorLinks = document.querySelectorAll('a[href^="#"]');
        
        anchorLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const targetId = link.getAttribute('href').substring(1);
                const targetElement = document.getElementById(targetId);
                
                if (targetElement) {
                    targetElement.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            });
        });
    }

    // Setup entrance animations
    setupAnimations() {
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const animationObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }
            });
        }, observerOptions);

        // Animate sections on scroll
        const animatedElements = document.querySelectorAll('.section-card, .overview-item, .workflow-step, .identifier-card, .safety-feature, .platform-card, .resource-card');
        
        animatedElements.forEach((element, index) => {
            element.style.opacity = '0';
            element.style.transform = 'translateY(30px)';
            element.style.transition = `all 0.6s cubic-bezier(0.4, 0, 0.2, 1) ${index * 0.1}s`;
            animationObserver.observe(element);
        });
    }

    // Setup copy functionality for code elements
    setupCopyCodeElements() {
        const codeElements = document.querySelectorAll('code');
        
        codeElements.forEach(code => {
            if (code.textContent.length > 20) { // Only add copy to longer code snippets
                code.style.position = 'relative';
                code.style.cursor = 'pointer';
                code.title = 'Click to copy';
                
                code.addEventListener('click', async () => {
                    try {
                        await navigator.clipboard.writeText(code.textContent);
                        this.showCopyFeedback(code);
                    } catch (err) {
                        console.error('Failed to copy text: ', err);
                    }
                });
            }
        });
    }

    // Show copy feedback
    showCopyFeedback(element) {
        const originalBg = element.style.background;
        const originalColor = element.style.color;
        
        element.style.background = 'rgba(16, 185, 129, 0.3)';
        element.style.color = '#10b981';
        
        setTimeout(() => {
            element.style.background = originalBg;
            element.style.color = originalColor;
        }, 1000);
        
        // Create floating "Copied!" message
        const feedback = document.createElement('div');
        feedback.textContent = 'Copied!';
        feedback.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(16, 185, 129, 0.9);
            color: white;
            padding: 0.75rem 1.5rem;
            border-radius: 8px;
            font-weight: 600;
            z-index: 10000;
            animation: copyFeedback 2s ease-out forwards;
            pointer-events: none;
        `;
        
        document.body.appendChild(feedback);
        
        setTimeout(() => {
            if (feedback.parentNode) {
                feedback.remove();
            }
        }, 2000);
        
        // Add CSS animation if not exists
        if (!document.getElementById('copy-feedback-style')) {
            const style = document.createElement('style');
            style.id = 'copy-feedback-style';
            style.textContent = `
                @keyframes copyFeedback {
                    0% {
                        opacity: 0;
                        transform: translateY(-20px) scale(0.8);
                    }
                    20% {
                        opacity: 1;
                        transform: translateY(0) scale(1);
                    }
                    80% {
                        opacity: 1;
                        transform: translateY(0) scale(1);
                    }
                    100% {
                        opacity: 0;
                        transform: translateY(-20px) scale(0.8);
                    }
                }
            `;
            document.head.appendChild(style);
        }
    }

    // Add interactive elements
    addInteractiveElements() {
        // Add hover effects to timeline items
        const timelineItems = document.querySelectorAll('.timeline-item');
        timelineItems.forEach((item, index) => {
            item.addEventListener('mouseenter', () => {
                item.style.transform = 'translateX(15px)';
            });
            
            item.addEventListener('mouseleave', () => {
                item.style.transform = 'translateX(0)';
            });
        });

        // Add click effects to overview items
        const overviewItems = document.querySelectorAll('.overview-item');
        overviewItems.forEach(item => {
            item.addEventListener('click', () => {
                this.addClickRipple(item);
            });
        });

        // Add interactive badges
        const badges = document.querySelectorAll('.section-badge');
        badges.forEach(badge => {
            badge.addEventListener('mouseenter', () => {
                badge.style.transform = 'scale(1.05)';
            });
            
            badge.addEventListener('mouseleave', () => {
                badge.style.transform = 'scale(1)';
            });
        });
    }

    // Add click ripple effect
    addClickRipple(element) {
        const rect = element.getBoundingClientRect();
        const ripple = document.createElement('span');
        const size = Math.max(rect.width, rect.height);
        const x = event.clientX - rect.left - size / 2;
        const y = event.clientY - rect.top - size / 2;
        
        ripple.style.cssText = `
            position: absolute;
            width: ${size}px;
            height: ${size}px;
            left: ${x}px;
            top: ${y}px;
            background: rgba(139, 92, 246, 0.3);
            border-radius: 50%;
            transform: scale(0);
            animation: ripple 0.6s ease-out;
            pointer-events: none;
        `;
        
        element.style.position = 'relative';
        element.style.overflow = 'hidden';
        element.appendChild(ripple);
        
        setTimeout(() => ripple.remove(), 600);
    }

    // Add progress indicator for reading
    addProgressIndicator() {
        const progressBar = document.createElement('div');
        progressBar.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 0%;
            height: 3px;
            background: linear-gradient(90deg, #8b5cf6, #3b82f6, #06b6d4);
            z-index: 10000;
            transition: width 0.3s ease;
        `;
        document.body.appendChild(progressBar);

        window.addEventListener('scroll', () => {
            const scrolled = (window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100;
            progressBar.style.width = scrolled + '%';
        });
    }
}

// Initialize the help page when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const helpApp = new HelpPageApp();
    helpApp.addProgressIndicator();
});

// Export for debugging
window.HelpPageApp = HelpPageApp;