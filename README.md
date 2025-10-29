# AR Repair Part Generator

**Measure broken objects → Generate 3D-printable replacement parts**

## 🎯 The Concept

This app is a **guided measurement tool** that helps users:
1. Measure broken/missing parts using AR markers
2. Select or AI-suggest a simple parametric shape (shim, bracket, washer, etc.)
3. Generate a custom 3D model based on measurements
4. Export STL for 3D printing

**Not trying to AI-identify complex objects** — just helping people measure and rebuild simple replacement parts.

## 🛠️ How It Works

### User Flow
1. **Describe what you need** (or pick from templates)
   - "I need a bracket that's 3cm wide"
   - "Small spacer for wobbly table leg"
   
2. **Place AR markers** and tap points to measure
   - Length, width, thickness
   - Hole sizes and positions
   
3. **AI suggests parameters** (optional)
   - Picks best shape archetype
   - Suggests tolerances and material
   
4. **Preview & adjust** the 3D model
   
5. **Download STL** and print!

## 📦 Part Library (6 Archetypes)

- **Shim** - Rectangular spacer
- **Washer** - Disc with center hole
- **L-Bracket** - L-shaped support with optional holes
- **U-Clamp** - U shape with mounting holes
- **Face Plate** - Flat plate with hole pattern
- **Clip** - C-shaped spring clip

Each is fully parametric and generated from measurements.

## 🤖 Light AI Layer

Uses GPT/LLM to:
- **Classify user intent** → pick appropriate archetype
- **Fill parameters** from AR measurements
- **Suggest tolerances** (press fit vs clearance)
- **Material recommendations** (PLA, PETG, infill %)

**Returns structured JSON** - no fuzzy parsing needed.

## 🚀 Tech Stack

- **AR.js** - Marker-based AR (works on iPhone Safari!)
- **Three.js** - 3D rendering and geometry
- **Parametric CAD** - Custom shape generators
- **OpenAI API** - Light AI suggestions
- **STL Export** - Ready for slicing

## 📱 Works On

- ✅ iPhone Safari (with AR markers)
- ✅ Android Chrome
- ✅ Desktop (measurement simulation)

No special apps required!

## 🚀 Getting Started

### Prerequisites
- Node.js 16+ installed
- OpenAI API key (optional, for AI suggestions)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/ar-repair-generator.git
cd ar-repair-generator
```

2. **Install dependencies**
```bash
npm install
```

3. **Configure OpenAI API (Optional)**
```bash
cp .env.example .env
# Edit .env and add your API key
```

If you skip this step, the app will use rule-based fallbacks instead of AI suggestions.

4. **Start development server**
```bash
npm run dev
```

5. **Open in browser**
```
http://localhost:3000
```

### For Mobile Testing

1. Find your local IP address:
   - Mac/Linux: `ifconfig | grep "inet "`
   - Windows: `ipconfig`

2. Access on your phone:
   ```
   http://YOUR_IP:3000
   ```

3. For AR features on mobile, you may need HTTPS:
   ```bash
   npm run dev -- --https
   ```

### Usage Guide

#### Demo Mode (Desktop)
1. Click on the grid plane to place measurement points
2. Each pair of points creates a measurement
3. Select a part type from the buttons
4. Click "Generate Part" to create the 3D model
5. Download the STL file

#### AR Mode (Mobile with camera)
1. Grant camera permissions
2. Point at AR markers (or flat surface)
3. Tap to place measurement points
4. Follow the same steps as demo mode

#### With AI Suggestions
1. Click "Add Key" when prompted (or skip for defaults)
2. When generating, you can describe what you need
3. AI will suggest the best part type and parameters
4. Review the generated model and export

### Project Structure

```
ar-repair-generator/
├── src/
│   ├── main.js              # Main application logic
│   ├── ar-manager.js        # AR measurement handling
│   ├── part-generators.js   # Parametric shape generation
│   ├── ai-assistant.js      # OpenAI integration
│   ├── stl-exporter.js      # STL export functionality
│   └── config.js            # Configuration & AI prompts
├── index.html               # Main HTML file
├── package.json             # Dependencies
├── vite.config.js           # Vite configuration
└── README.md                # This file
```

### Building for Production

```bash
npm run build
```

The built files will be in the `dist/` directory, ready to deploy to any static hosting service.

## 🎓 For H2H Project

Demonstrates:
- AR measurement techniques
- Parametric CAD generation
- Practical AI integration (not magic)
- Maker/fabrication pipeline
- Real-world problem solving

## 🧪 Example AI Prompts

The system includes few-shot examples for consistent AI responses:

**Example 1: Wobbly table shim**
```
Input: "I need to stop a wobbly table; gap looks ~2 mm."
AR Measurements: { gap: 1.8, foot_area: {length: 30, width: 25} }

Output: Shim, 30x25x2mm, with 0.5mm chamfer
Material: PLA, 20% infill
```

**Example 2: Shelf bracket**
```
Input: "Bracket to hold a shelf; legs about 40 and 60 mm"
AR Measurements: { leg_a: 39.6, leg_b: 59.1, hole_d: 4.2 }

Output: L-bracket, 40x60x3mm, with M4 clearance holes
Material: PETG, 40% infill
```

## 🔧 Customization

### Adding New Part Types

1. Define in `src/config.js`:
```javascript
my_part: {
  name: 'My Part',
  emoji: '🔧',
  description: 'Description here',
  requiredParams: ['param1', 'param2'],
  optionalParams: ['param3']
}
```

2. Create generator in `src/part-generators.js`:
```javascript
export function generateMyPart(params) {
  // Use Three.js to create geometry
  // Return THREE.Mesh
}
```

3. Add to factory function in same file

### Adjusting AI Behavior

Edit `AI_SYSTEM_PROMPT` in `src/config.js` to change:
- Part selection logic
- Tolerance recommendations
- Material suggestions
- Parameter inference rules

## 📝 License

MIT

## 🙏 Acknowledgments

- Three.js for 3D rendering
- OpenAI for AI assistance
- AR.js for marker-based AR

