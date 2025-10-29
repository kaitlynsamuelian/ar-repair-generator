# Quick Setup Guide

## Step 1: Install Dependencies

```bash
npm install
```

## Step 2: Configure API Key (Optional)

The app works without an API key using rule-based fallbacks. For AI suggestions:

1. Copy `env.example` to `.env`:
```bash
cp env.example .env
```

2. Get an OpenAI API key from: https://platform.openai.com/api-keys

3. Edit `.env` and replace `your_openai_api_key_here` with your actual key

**Alternative:** You can also add the key directly in the browser when the app prompts you. It will be stored in localStorage.

## Step 3: Run the Development Server

```bash
npm run dev
```

## Step 4: Open in Browser

Visit: http://localhost:3000

## Testing the App

### Desktop Demo Mode
1. Click on the grid to place measurement points
2. Two clicks = one measurement
3. Select a part type (e.g., "Shim")
4. Click "Generate Part"
5. Preview the rotating 3D model
6. Click "Export STL" to download

### Mobile AR Mode
1. Open the app on your phone (use your computer's IP address)
2. Grant camera permissions
3. Tap the screen to place measurement points
4. Follow the same steps as desktop

## Troubleshooting

### "Failed to initialize AR"
- Desktop: This is normal, the app uses demo mode with a grid
- Mobile: Check camera permissions

### "AI Features" warning
- This is normal if you haven't set up an API key
- Click "Skip" to use rule-based defaults
- Or click "Add Key" to enter your OpenAI API key

### Port already in use
```bash
npm run dev -- --port 3001
```

### Can't access from phone
1. Make sure your phone is on the same WiFi network
2. Find your computer's IP address:
   - Mac: `ifconfig | grep "inet "`
   - Windows: `ipconfig`
   - Linux: `ip addr show`
3. Use `http://YOUR_IP:3000` on your phone

## Next Steps

1. Try generating different part types
2. Experiment with measurements
3. Export and slice an STL file
4. Print your first repair part!

## File Structure

```
src/
├── main.js            - Main app controller
├── ar-manager.js      - AR and measurement logic
├── part-generators.js - 3D shape generation
├── ai-assistant.js    - OpenAI integration
├── stl-exporter.js    - STL file export
└── config.js          - Configuration and AI prompts
```

## Customization Ideas

1. **Add more part types**: Edit `src/config.js` and `src/part-generators.js`
2. **Tune AI suggestions**: Modify `AI_SYSTEM_PROMPT` in `src/config.js`
3. **Change tolerances**: Update `CONSTRAINTS` in `src/config.js`
4. **Styling**: Edit the `<style>` section in `index.html`

## Build for Production

```bash
npm run build
```

Deploy the `dist/` folder to any static hosting:
- Netlify
- Vercel
- GitHub Pages
- Your own server

Enjoy building repair parts! 🛠️

