// Shape Recipe System - Flexible AI-powered parametric shapes
import * as THREE from 'three';
import { Brush, Evaluator, ADDITION, SUBTRACTION, INTERSECTION } from 'three-bvh-csg';

/**
 * Shape Recipe Structure:
 * {
 *   description: "Water bottle lid",
 *   steps: [
 *     {
 *       id: 1,
 *       operation: "add",
 *       shape: "cylinder",
 *       params: { diameter: 30, height: 15 },
 *       position: [0, 0, 0],
 *       note: "Main body"
 *     }
 *   ]
 * }
 */

export class ShapeRecipeEngine {
  constructor() {
    this.evaluator = new Evaluator();
  }

  /**
   * Generate primitive shapes
   */
  createPrimitive(shape, params) {
    let geometry;

    switch (shape) {
      case 'cylinder':
        geometry = new THREE.CylinderGeometry(
          params.diameter / 2,
          params.diameter / 2,
          params.height,
          32
        );
        break;

      case 'box':
        geometry = new THREE.BoxGeometry(
          params.length || params.width,
          params.height,
          params.width || params.depth
        );
        break;

      case 'sphere':
        geometry = new THREE.SphereGeometry(
          params.diameter / 2,
          32,
          32
        );
        break;

      case 'cone':
        geometry = new THREE.CylinderGeometry(
          (params.top_d || params.top_diameter) / 2,
          (params.bottom_d || params.bottom_diameter) / 2,
          params.height,
          32
        );
        break;

      case 'torus':
        geometry = new THREE.TorusGeometry(
          params.major_radius || params.diameter / 2,
          params.minor_radius || params.tube_diameter / 2,
          16,
          32
        );
        break;

      default:
        throw new Error(`Unknown shape type: ${shape}`);
    }

    return geometry;
  }

  /**
   * Execute a recipe and return the final mesh
   */
  async executeRecipe(recipe) {
    if (!recipe.steps || recipe.steps.length === 0) {
      throw new Error('Recipe has no steps');
    }

    let resultBrush = null;

    for (const step of recipe.steps) {

      // Create primitive geometry
      const geometry = this.createPrimitive(step.shape, step.params);

      // Create brush from geometry
      const brush = new Brush(geometry);

      // Apply position if specified
      if (step.position) {
        brush.position.set(
          step.position[0] || 0,
          step.position[1] || 0,
          step.position[2] || 0
        );
      }

      brush.updateMatrixWorld();

      // Apply operation
      if (resultBrush === null) {
        // First step always adds
        resultBrush = brush;
      } else {
        switch (step.operation) {
          case 'add':
            resultBrush = this.evaluator.evaluate(resultBrush, brush, ADDITION);
            break;
          case 'subtract':
            resultBrush = this.evaluator.evaluate(resultBrush, brush, SUBTRACTION);
            break;
          case 'intersect':
            resultBrush = this.evaluator.evaluate(resultBrush, brush, INTERSECTION);
            break;
          default:
            throw new Error(`Unknown operation: ${step.operation}`);
        }
      }
    }

    // Convert to mesh with material
    const material = new THREE.MeshStandardMaterial({
      color: 0x4CAF50,
      roughness: 0.7,
      metalness: 0.2
    });

    const mesh = new THREE.Mesh(resultBrush.geometry, material);
    return mesh;
  }

  /**
   * Validate recipe structure
   */
  validateRecipe(recipe) {
    const errors = [];

    if (!recipe.steps || !Array.isArray(recipe.steps)) {
      errors.push('Recipe must have a steps array');
      return { valid: false, errors };
    }

    if (recipe.steps.length === 0) {
      errors.push('Recipe must have at least one step');
      return { valid: false, errors };
    }

    recipe.steps.forEach((step, index) => {
      if (!step.id) errors.push(`Step ${index} missing id`);
      if (!step.shape) errors.push(`Step ${index} missing shape`);
      if (!step.operation) errors.push(`Step ${index} missing operation`);
      if (!step.params) errors.push(`Step ${index} missing params`);
    });

    return { valid: errors.length === 0, errors };
  }
}

/**
 * Example recipes
 */
export const EXAMPLE_RECIPES = {
  water_bottle_lid: {
    description: "Screw-on water bottle lid",
    steps: [
      {
        id: 1,
        operation: "add",
        shape: "cylinder",
        params: { diameter: 30, height: 15 },
        position: [0, 0, 0],
        note: "Main body"
      },
      {
        id: 2,
        operation: "subtract",
        shape: "cylinder",
        params: { diameter: 27.7, height: 12 },
        position: [0, 1.5, 0],
        note: "Inner cavity"
      },
      {
        id: 3,
        operation: "add",
        shape: "cylinder",
        params: { diameter: 28, height: 3 },
        position: [0, -6, 0],
        note: "Top seal"
      }
    ]
  },

  simple_funnel: {
    description: "Simple funnel",
    steps: [
      {
        id: 1,
        operation: "add",
        shape: "cone",
        params: { top_d: 50, bottom_d: 10, height: 60 },
        position: [0, 0, 0],
        note: "Outer cone"
      },
      {
        id: 2,
        operation: "subtract",
        shape: "cone",
        params: { top_d: 48, bottom_d: 8, height: 58 },
        position: [0, 0, 0],
        note: "Inner cavity"
      }
    ]
  },

  custom_knob: {
    description: "Grip knob",
    steps: [
      {
        id: 1,
        operation: "add",
        shape: "cylinder",
        params: { diameter: 20, height: 30 },
        position: [0, 0, 0],
        note: "Main cylinder"
      },
      {
        id: 2,
        operation: "add",
        shape: "sphere",
        params: { diameter: 15 },
        position: [0, 15, 0],
        note: "Rounded top"
      },
      {
        id: 3,
        operation: "subtract",
        shape: "cylinder",
        params: { diameter: 6, height: 35 },
        position: [0, 0, 0],
        note: "Center hole"
      }
    ]
  }
};

