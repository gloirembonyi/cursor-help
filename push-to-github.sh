#!/bin/bash

echo "🚀 Cursor Helper - GitHub Push Script"
echo "======================================"
echo ""
echo "This script will help you push your code to GitHub."
echo ""

# Check if we're in the right directory
if [ ! -f "go.mod" ]; then
    echo "❌ Error: Not in the project root directory"
    echo "Please run this script from the go-cursor-help directory"
    exit 1
fi

echo "📁 Current directory: $(pwd)"
echo ""

# Check git status
echo "📊 Git Status:"
git status
echo ""

# Check remote URL
echo "🔗 Remote Repository:"
git remote -v
echo ""

# Push to GitHub
echo "🚀 Pushing to GitHub..."
echo "Note: You may need to authenticate with GitHub"
echo ""

git push -u origin master

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to GitHub!"
    echo "🌐 Your repository: https://github.com/gloirembonyi/cursor-help"
    echo ""
    echo "🎉 Your professional Cursor Helper web interface is now available!"
    echo "📚 Features pushed:"
    echo "   • Modern Web UI with Huly-inspired design"
    echo "   • Interactive help documentation"
    echo "   • Cross-platform support"
    echo "   • Professional animations and effects"
    echo "   • Educational content explaining how it works"
else
    echo ""
    echo "❌ Push failed. This might be due to authentication issues."
    echo ""
    echo "💡 Solutions:"
    echo "1. Use GitHub Desktop for easier authentication"
    echo "2. Set up a Personal Access Token:"
    echo "   • Go to GitHub Settings > Developer settings > Personal access tokens"
    echo "   • Generate a new token with 'repo' permissions"
    echo "   • Use the token as your password when prompted"
    echo ""
    echo "3. Or use SSH authentication:"
    echo "   • Set up SSH keys in GitHub"
    echo "   • Change remote URL to SSH: git remote set-url origin git@github.com:gloirembonyi/cursor-help.git"
fi