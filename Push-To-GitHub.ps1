# 🚀 Cursor Helper - GitHub Push Script
Write-Host "🚀 Cursor Helper - GitHub Push Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will help you push your code to GitHub." -ForegroundColor Yellow
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "go.mod")) {
    Write-Host "❌ Error: Not in the project root directory" -ForegroundColor Red
    Write-Host "Please run this script from the go-cursor-help directory" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Current directory: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Check git status
Write-Host "📊 Git Status:" -ForegroundColor Blue
git status
Write-Host ""

# Check remote URL
Write-Host "🔗 Remote Repository:" -ForegroundColor Blue
git remote -v
Write-Host ""

# Show what we're about to push
Write-Host "📦 Files to be pushed:" -ForegroundColor Magenta
Write-Host "   • cmd/cursor-web-ui/main.go - Web server entry point" -ForegroundColor White
Write-Host "   • internal/web/ - Go web server and API handlers" -ForegroundColor White
Write-Host "   • web/templates/ - Professional HTML templates" -ForegroundColor White
Write-Host "   • web/static/css/ - Huly-inspired CSS with animations" -ForegroundColor White
Write-Host "   • web/static/js/ - Interactive JavaScript applications" -ForegroundColor White
Write-Host "   • web/templates/help.html - Comprehensive documentation" -ForegroundColor White
Write-Host ""

# Push to GitHub
Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Yellow
Write-Host "Note: You may need to authenticate with GitHub" -ForegroundColor Yellow
Write-Host ""

try {
    git push -u origin master
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Successfully pushed to GitHub!" -ForegroundColor Green
        Write-Host "🌐 Your repository: https://github.com/gloirembonyi/cursor-help" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "🎉 Your professional Cursor Helper web interface is now available!" -ForegroundColor Green
        Write-Host "📚 Features pushed:" -ForegroundColor Blue
        Write-Host "   • Modern Web UI with Huly-inspired design" -ForegroundColor White
        Write-Host "   • Interactive help documentation" -ForegroundColor White
        Write-Host "   • Cross-platform support" -ForegroundColor White
        Write-Host "   • Professional animations and effects" -ForegroundColor White
        Write-Host "   • Educational content explaining how it works" -ForegroundColor White
        Write-Host ""
        Write-Host "🔧 To run the web interface:" -ForegroundColor Yellow
        Write-Host "   go run ./cmd/cursor-web-ui/main.go" -ForegroundColor Cyan
        Write-Host "   Then visit: http://localhost:8080" -ForegroundColor Cyan
    } else {
        throw "Push failed"
    }
} catch {
    Write-Host ""
    Write-Host "❌ Push failed. This might be due to authentication issues." -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Solutions:" -ForegroundColor Yellow
    Write-Host "1. Use GitHub Desktop for easier authentication" -ForegroundColor White
    Write-Host "2. Set up a Personal Access Token:" -ForegroundColor White
    Write-Host "   • Go to GitHub Settings > Developer settings > Personal access tokens" -ForegroundColor Gray
    Write-Host "   • Generate a new token with 'repo' permissions" -ForegroundColor Gray
    Write-Host "   • Use the token as your password when prompted" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Or try manual push:" -ForegroundColor White
    Write-Host "   git push -u origin master" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "4. Alternative: Use SSH authentication" -ForegroundColor White
    Write-Host "   git remote set-url origin git@github.com:gloirembonyi/cursor-help.git" -ForegroundColor Gray
}