// Main application entry point
import * as THREE from 'three';
import { ARManager } from './ar-manager.js';
import { AIAssistant } from './ai-assistant.js';
import { STLExporter, prepareMeshForExport } from './stl-exporter.js';
import { generatePart, validateParameters } from './part-generators.js';
import { PART_TYPES, CONSTRAINTS } from './config.js';
import { ShapeRecipeEngine } from './shape-recipe.js';

class RepairPartGenerator {
  constructor() {
    this.arManager = null;
    this.aiAssistant = null;
    this.stlExporter = new STLExporter();
    this.recipeEngine = new ShapeRecipeEngine();
    
    this.selectedPartType = null;
    this.currentPart = null;
    this.currentSpec = null;
    this.currentRecipe = null;
    
    this.elements = {
      status: document.getElementById('status'),
      instructions: document.getElementById('instructions'),
      measurements: document.getElementById('measurements'),
      measurementList: document.getElementById('measurement-list'),
      generateBtn: document.getElementById('generate-btn'),
      exportBtn: document.getElementById('export-btn'),
      clearBtn: document.getElementById('clear-btn'),
      arScene: document.getElementById('ar-scene'),
      debugMode: document.getElementById('debug-mode'),
      modeToggleBtn: document.getElementById('mode-toggle-btn'),
      customShapeBtn: document.getElementById('custom-shape-btn'),
      recipeViewer: document.getElementById('recipe-viewer'),
      recipeSteps: document.getElementById('recipe-steps'),
      controls: document.getElementById('controls'),
      controlsToggle: document.getElementById('controls-toggle')
    };
    
    this.preferredMode = localStorage.getItem('preferred_mode') || 'auto'; // auto, demo, camera
  }

  /**
   * Initialize the application
   */
  async init() {
    try {
      const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
      if (isMobile) {
        this.updateStatus('Requesting camera access...', 'orange');
        this.updateInstructions('📷 Please allow camera access when prompted');
      } else {
        this.updateStatus('Initializing...', 'orange');
      }

      // Initialize AR Manager with preferred mode
      this.arManager = new ARManager();
      const arInitialized = await this.arManager.initialize(this.elements.arScene, this.preferredMode);

      if (!arInitialized) {
        throw new Error('Failed to initialize AR');
      }

      // Setup AR measurement callback
      this.arManager.onMeasurementUpdate = (measurements) => {
        this.onMeasurementsUpdated(measurements);
      };

      // Initialize AI Assistant
      const apiKey = this.getAPIKey();
      this.aiAssistant = new AIAssistant(apiKey);

      // Setup event listeners
      this.setupEventListeners();

      // Update status and mode toggle button
      if (this.arManager.demoMode) {
        // Detect if mobile
        const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
        this.updateStatus('Demo Mode - Ready!', '#4CAF50');
        
        // Update toggle button
        this.elements.modeToggleBtn.textContent = '📷 Try Camera';
        this.elements.modeToggleBtn.style.background = 'rgba(33, 150, 243, 0.9)';
        
        // Show why camera failed if applicable
        if (this.arManager.cameraErrorMessage) {
          this.elements.debugMode.textContent = this.arManager.cameraErrorMessage;
          this.elements.debugMode.style.color = '#ff9800';
        } else {
          this.elements.debugMode.textContent = 'Mode: Demo (Grid)';
        }
        
        if (isMobile) {
          this.updateInstructions('📱 Tap the green grid to place measurement points');
        } else {
          this.updateInstructions('🖱️ Click the green grid to place measurement points');
        }
      } else {
        this.updateStatus('📷 Camera Active - Tap to measure!', '#4CAF50');
        this.elements.debugMode.textContent = 'Mode: Camera (AR)';
        this.updateInstructions('📱 Tap the screen to place measurement points on objects');
        
        // Update toggle button
        this.elements.modeToggleBtn.textContent = '🎮 Demo Mode';
        this.elements.modeToggleBtn.style.background = 'rgba(255, 152, 0, 0.9)';
      }

    } catch (error) {
      console.error('Initialization failed:', error);
      this.updateStatus('Failed to initialize - ' + error.message, 'red');
    }
  }

  /**
   * Get OpenAI API key from localStorage or environment
   */
  getAPIKey() {
    // Try localStorage first (user can set it in the app)
    let apiKey = localStorage.getItem('openai_api_key');
    
    // Fall back to environment variable (for local dev)
    if (!apiKey && import.meta.env && import.meta.env.VITE_OPENAI_API_KEY) {
      apiKey = import.meta.env.VITE_OPENAI_API_KEY;
    }
    
    return apiKey || null;
  }

  /**
   * Setup UI event listeners
   */
  setupEventListeners() {
    // Part type selection
    document.querySelectorAll('.part-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        this.selectPartType(btn.dataset.part);
      });
    });

    // Generate button
    this.elements.generateBtn.addEventListener('click', () => {
      this.generatePart();
    });

    // Export button
    this.elements.exportBtn.addEventListener('click', () => {
      this.exportSTL();
    });

    // Clear button
    this.elements.clearBtn.addEventListener('click', () => {
      this.clearAll();
    });

    // Mode toggle button
    this.elements.modeToggleBtn.addEventListener('click', () => {
      this.toggleMode();
    });

    // Custom shape button
    this.elements.customShapeBtn.addEventListener('click', () => {
      this.generateCustomShape();
    });

    // Controls toggle
    this.elements.controlsToggle.addEventListener('click', () => {
      this.toggleControls();
    });

    // API key input (add a button in UI if needed)
    this.setupAPIKeyInput();
  }

  /**
   * Setup API key input (optional UI element)
   */
  setupAPIKeyInput() {
    // Check if user needs to set API key
    if (!this.aiAssistant.isConfigured()) {
      // Don't show the notice - API key is optional
      console.log('💡 Tip: Add OpenAI API key in .env for AI-powered custom shapes');
    }
  }

  /**
   * Select a part type
   */
  selectPartType(partType) {
    this.selectedPartType = partType;
    
    // Update UI
    document.querySelectorAll('.part-btn').forEach(btn => {
      btn.classList.remove('active');
    });
    document.querySelector(`[data-part="${partType}"]`).classList.add('active');

    // Enable generate button if we have measurements
    this.updateGenerateButton();

    // Update instructions
    const info = PART_TYPES[partType];
    this.updateInstructions(`Selected: ${info.emoji} ${info.name} - ${info.description}`);
  }

  /**
   * Handle measurement updates
   */
  onMeasurementsUpdated(measurements) {
    const count = Object.keys(measurements).length;
    
    if (count > 0) {
      // Show measurements
      this.elements.measurements.style.display = 'block';
      this.elements.measurementList.innerHTML = Object.entries(measurements)
        .map(([key, value]) => `<div>${key}: ${value}mm</div>`)
        .join('');
      
      // Update generate button
      this.updateGenerateButton();
    } else {
      this.elements.measurements.style.display = 'none';
    }
  }

  /**
   * Update generate button state
   */
  updateGenerateButton() {
    const measurements = this.arManager.getMeasurements();
    const hasMeasurements = Object.keys(measurements).length > 0;
    const hasPartType = !!this.selectedPartType;
    
    this.elements.generateBtn.disabled = !(hasMeasurements || hasPartType);
    
    if (hasPartType && !hasMeasurements) {
      this.elements.generateBtn.textContent = 'Generate with Defaults';
    } else if (hasPartType && hasMeasurements) {
      this.elements.generateBtn.textContent = 'Generate Part';
    } else {
      this.elements.generateBtn.textContent = 'Select Part Type';
    }
  }

  /**
   * Generate part from measurements and selection
   */
  async generatePart() {
    try {
      this.updateStatus('Generating part...', 'orange');
      
      // Get measurements
      const measurements = this.arManager.getMeasurementsForAI();
      
      // If no part type selected, try AI suggestion
      if (!this.selectedPartType) {
        if (this.aiAssistant.isConfigured()) {
          const description = prompt('Describe what you need:') || 'basic spacer';
          this.currentSpec = await this.aiAssistant.suggestPart(description, measurements);
          this.selectedPartType = this.currentSpec.part_type;
        } else {
          alert('Please select a part type first');
          return;
        }
      } else {
        // Use AI to suggest parameters if available
        if (this.aiAssistant.isConfigured() && Object.keys(measurements).length > 0) {
          const description = `${PART_TYPES[this.selectedPartType].name} based on measurements`;
          this.currentSpec = await this.aiAssistant.suggestPart(description, measurements);
        } else {
          // Use fallback
          this.currentSpec = this.aiAssistant.fallbackSuggestion(
            PART_TYPES[this.selectedPartType].name,
            measurements,
            CONSTRAINTS
          );
        }
      }

      // Validate parameters
      const validation = validateParameters(
        this.currentSpec.part_type,
        this.currentSpec.parameters,
        CONSTRAINTS
      );

      if (!validation.valid) {
        throw new Error('Invalid parameters: ' + validation.errors.join(', '));
      }

      // Generate 3D model
      this.currentPart = generatePart(
        this.currentSpec.part_type,
        this.currentSpec.parameters
      );

      // Add to scene
      this.arManager.addPartToScene(this.currentPart);

      // Show export button
      this.elements.exportBtn.style.display = 'block';

      // Update status
      this.updateStatus('Part generated! Rotate to view', 'green');
      
      // Show AI notes if available
      if (this.currentSpec.notes) {
        this.updateInstructions(`💡 ${this.currentSpec.notes}`);
      }

      // Log spec for debugging
      console.log('Generated spec:', this.currentSpec);

    } catch (error) {
      console.error('Failed to generate part:', error);
      this.updateStatus('Failed: ' + error.message, 'red');
    }
  }

  /**
   * Export current part as STL
   */
  exportSTL() {
    if (!this.currentPart) {
      alert('No part to export');
      return;
    }

    try {
      this.updateStatus('Exporting STL...', 'orange');

      // Prepare mesh for export
      const meshToExport = this.currentPart.clone();
      
      // Reset scale (we scaled it down for viewing)
      meshToExport.scale.set(1, 1, 1);
      
      prepareMeshForExport(meshToExport);

      // Generate filename
      const partName = this.currentSpec.part_type || 'part';
      const timestamp = new Date().toISOString().split('T')[0];
      const filename = `${partName}_${timestamp}.stl`;

      // Download
      this.stlExporter.download(meshToExport, filename, true);

      this.updateStatus('STL exported successfully!', 'green');

      setTimeout(() => {
        this.updateInstructions('🎉 Ready to print! Load the STL file in your slicer.');
      }, 500);

    } catch (error) {
      console.error('Export failed:', error);
      this.updateStatus('Export failed: ' + error.message, 'red');
    }
  }

  /**
   * Generate custom shape using AI recipe
   */
  async generateCustomShape() {
    try {
      // Prompt user for what they want
      const description = prompt('What do you want to create?\n\nExamples:\n- "Water bottle lid"\n- "Funnel"\n- "Custom knob with hole"\n- "Phone stand"');
      
      if (!description) return;

      this.updateStatus('🤖 AI generating shape recipe...', 'orange');
      
      // Get measurements
      const measurements = this.arManager.getMeasurementsForAI();
      
      // Generate recipe
      let recipe;
      if (this.aiAssistant.isConfigured()) {
        recipe = await this.aiAssistant.generateShapeRecipe(description, measurements);
      } else {
        // Use fallback
        recipe = this.aiAssistant.fallbackRecipe(description, measurements);
      }
      
      this.currentRecipe = recipe;
      console.log('📜 Generated recipe:', recipe);
      
      // Display recipe
      this.displayRecipe(recipe);
      
      // Execute recipe to generate mesh
      this.updateStatus('Building 3D model from recipe...', 'orange');
      this.currentPart = await this.recipeEngine.executeRecipe(recipe);
      
      // Add to scene
      this.arManager.addPartToScene(this.currentPart);
      
      // Show export button
      this.elements.exportBtn.style.display = 'block';
      
      this.updateStatus('✨ Custom shape generated!', '#4CAF50');
      this.updateInstructions(`🎉 ${recipe.description} - Ready to export!`);
      
    } catch (error) {
      console.error('Failed to generate custom shape:', error);
      this.updateStatus('❌ Failed: ' + error.message, 'red');
      alert('Failed to generate shape. Try:\n- Simpler description\n- Check AI key if using AI\n- Try again');
    }
  }

  /**
   * Display recipe in UI
   */
  displayRecipe(recipe) {
    this.elements.recipeViewer.style.display = 'block';
    
    const stepsHTML = recipe.steps.map(step => `
      <div style="
        background: rgba(0,0,0,0.3);
        padding: 8px;
        margin: 4px 0;
        border-radius: 4px;
        font-size: 12px;
      ">
        <div style="font-weight: 600;">
          ${step.id}. [${step.operation.toUpperCase()}] ${step.shape}
        </div>
        <div style="opacity: 0.9; margin-top: 2px;">
          ${JSON.stringify(step.params)}
        </div>
        ${step.note ? `<div style="opacity: 0.7; font-size: 11px; margin-top: 2px;">${step.note}</div>` : ''}
      </div>
    `).join('');
    
    this.elements.recipeSteps.innerHTML = `
      <div style="font-size: 13px; margin-bottom: 6px; opacity: 0.9;">
        ${recipe.description}
      </div>
      ${stepsHTML}
    `;
  }

  /**
   * Toggle between camera and demo mode
   */
  async toggleMode() {
    // Determine new mode
    const newMode = this.arManager.demoMode ? 'camera' : 'demo';
    
    // Save preference
    localStorage.setItem('preferred_mode', newMode);
    
    // Show loading
    this.updateStatus('Switching modes...', 'orange');
    
    // Reload the page to reinitialize
    window.location.reload();
  }

  /**
   * Clear all measurements and generated parts
   */
  clearAll() {
    this.arManager.clearPoints();
    this.selectedPartType = null;
    this.currentPart = null;
    this.currentSpec = null;

    // Reset UI
    document.querySelectorAll('.part-btn').forEach(btn => {
      btn.classList.remove('active');
    });
    
    this.elements.exportBtn.style.display = 'none';
    this.elements.measurements.style.display = 'none';
    this.updateGenerateButton();
    
    this.updateStatus('Ready to measure', 'green');
    this.updateInstructions('Select a part type and take measurements');
  }

  /**
   * Update status message
   */
  updateStatus(message, color = 'white') {
    this.elements.status.textContent = message;
    this.elements.status.style.color = color;
  }

  /**
   * Update instructions
   */
  updateInstructions(message) {
    this.elements.instructions.textContent = message;
  }

  /**
   * Toggle controls panel
   */
  toggleControls() {
    const isCollapsed = this.elements.controls.classList.contains('collapsed');
    
    if (isCollapsed) {
      // Expand - show all controls
      this.elements.controls.classList.remove('collapsed');
      this.elements.controlsToggle.textContent = '▼';
    } else {
      // Collapse - hide everything except toggle button
      this.elements.controls.classList.add('collapsed');
      this.elements.controlsToggle.textContent = '▲';
    }
  }
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  const app = new RepairPartGenerator();
  app.init();
  
  // Expose for debugging
  window.app = app;
});

