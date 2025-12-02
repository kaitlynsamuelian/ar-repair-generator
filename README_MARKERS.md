# AR Repair Generator - Marker-Based Version

This is the **marker-based AR tracking** version of the AR Repair Generator.

## Key Differences from Main Version:

### Main Version (`ar-repair-generator`)
- ✅ Simple virtual plane overlay
- ✅ Tap anywhere to measure
- ✅ 3 scale modes (Small/Medium/Large)
- ✅ Works immediately, no setup needed
- ⚠️ Approximate measurements (scale calibration required)

### This Version (`ar-repair-generator-markers`)
- 🎯 Uses AR.js marker tracking
- 🎯 Requires printed marker (50mm x 50mm)
- 🎯 Real-world scale accuracy
- 🎯 Measurements anchored to physical space
- ⚠️ More complex setup
- ⚠️ Requires marker to be visible

## Getting Started:

1. Print the marker from `public/markers/marker-0.png` at exactly **50mm x 50mm**
2. Run `npm install` (AR.js dependencies needed)
3. Run `npm run dev`
4. Point camera at the marker
5. Tap to measure - measurements will be accurate to real-world scale

## Development Status:

This version is currently in **experimental/development** status. The main version is recommended for production use.

## Next Steps:

- Implement AR.js marker tracking
- Test accuracy with physical objects
- Compare results with main version

