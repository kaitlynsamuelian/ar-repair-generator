// Parametric shape generators for repair parts
import * as THREE from 'three';

/**
 * Generate a rectangular shim/spacer
 * @param {Object} params - {length, width, thickness, chamfer?}
 */
export function generateShim(params) {
  const { length, width, thickness, chamfer = 0 } = params;
  
  const geometry = new THREE.BoxGeometry(length, width, thickness);
  
  // Apply chamfer if specified (simplified - corners beveled)
  if (chamfer > 0) {
    // Note: For production, use THREE.BufferGeometry with custom vertices
    // This is a simplified version
  }
  
  const material = new THREE.MeshStandardMaterial({
    color: 0x4CAF50,
    roughness: 0.7,
    metalness: 0.2
  });
  
  return new THREE.Mesh(geometry, material);
}

/**
 * Generate a washer (disc with center hole)
 * @param {Object} params - {outer_d, inner_d, thickness}
 */
export function generateWasher(params) {
  const { outer_d, inner_d, thickness } = params;
  
  // Create outer cylinder
  const outerGeometry = new THREE.CylinderGeometry(
    outer_d / 2,
    outer_d / 2,
    thickness,
    32
  );
  
  // Create inner hole (we'll use CSG in real implementation)
  const innerGeometry = new THREE.CylinderGeometry(
    inner_d / 2,
    inner_d / 2,
    thickness + 0.1,
    32
  );
  
  // Rotate to lay flat (cylinder default is vertical)
  outerGeometry.rotateX(Math.PI / 2);
  innerGeometry.rotateX(Math.PI / 2);
  
  // For now, create a ring shape using THREE.Shape
  const shape = new THREE.Shape();
  shape.absarc(0, 0, outer_d / 2, 0, Math.PI * 2, false);
  
  const hole = new THREE.Path();
  hole.absarc(0, 0, inner_d / 2, 0, Math.PI * 2, true);
  shape.holes.push(hole);
  
  const extrudeSettings = {
    depth: thickness,
    bevelEnabled: false
  };
  
  const geometry = new THREE.ExtrudeGeometry(shape, extrudeSettings);
  geometry.rotateX(Math.PI / 2);
  geometry.translate(0, 0, -thickness / 2);
  
  const material = new THREE.MeshStandardMaterial({
    color: 0x2196F3,
    roughness: 0.7,
    metalness: 0.2
  });
  
  return new THREE.Mesh(geometry, material);
}

/**
 * Generate an L-bracket
 * @param {Object} params - {leg_a, leg_b, thickness, fillet?, holes?}
 */
export function generateLBracket(params) {
  const { leg_a, leg_b, thickness, fillet = 0, holes = [] } = params;
  
  // Create L-shape using Shape and extrude
  const shape = new THREE.Shape();
  
  // Draw L profile (centered at origin)
  shape.moveTo(0, 0);
  shape.lineTo(leg_a, 0);
  shape.lineTo(leg_a, thickness);
  shape.lineTo(thickness, thickness);
  shape.lineTo(thickness, leg_b);
  shape.lineTo(0, leg_b);
  shape.lineTo(0, 0);
  
  const extrudeSettings = {
    depth: thickness,
    bevelEnabled: fillet > 0,
    bevelThickness: fillet,
    bevelSize: fillet,
    bevelSegments: 3
  };
  
  const geometry = new THREE.ExtrudeGeometry(shape, extrudeSettings);
  
  // Rotate to standard orientation
  geometry.rotateY(Math.PI / 2);
  geometry.translate(-thickness / 2, -leg_b / 2, -leg_a / 2);
  
  // Add holes (simplified - would need CSG for proper subtraction)
  // In production, use three-bvh-csg or similar library
  
  const material = new THREE.MeshStandardMaterial({
    color: 0xFF9800,
    roughness: 0.7,
    metalness: 0.2
  });
  
  return new THREE.Mesh(geometry, material);
}

/**
 * Generate a U-clamp
 * @param {Object} params - {width, height, depth, thickness, holes?}
 */
export function generateUClamp(params) {
  const { width, height, depth, thickness, holes = [] } = params;
  
  // Create U-shape
  const shape = new THREE.Shape();
  
  // Outer rectangle
  shape.moveTo(-width / 2, 0);
  shape.lineTo(-width / 2, height);
  shape.lineTo(width / 2, height);
  shape.lineTo(width / 2, 0);
  
  // Inner cutout (U shape)
  const innerWidth = width - thickness * 2;
  const innerHeight = height - thickness;
  
  const hole = new THREE.Path();
  hole.moveTo(-innerWidth / 2, thickness);
  hole.lineTo(-innerWidth / 2, height);
  hole.lineTo(innerWidth / 2, height);
  hole.lineTo(innerWidth / 2, thickness);
  hole.lineTo(-innerWidth / 2, thickness);
  shape.holes.push(hole);
  
  const extrudeSettings = {
    depth: depth,
    bevelEnabled: false
  };
  
  const geometry = new THREE.ExtrudeGeometry(shape, extrudeSettings);
  geometry.translate(0, -height / 2, -depth / 2);
  
  const material = new THREE.MeshStandardMaterial({
    color: 0x9C27B0,
    roughness: 0.7,
    metalness: 0.2
  });
  
  return new THREE.Mesh(geometry, material);
}

/**
 * Generate a face plate with hole pattern
 * @param {Object} params - {length, width, thickness, holes?}
 */
export function generateFacePlate(params) {
  const { length, width, thickness, holes = [] } = params;
  
  const shape = new THREE.Shape();
  shape.moveTo(-length / 2, -width / 2);
  shape.lineTo(length / 2, -width / 2);
  shape.lineTo(length / 2, width / 2);
  shape.lineTo(-length / 2, width / 2);
  shape.lineTo(-length / 2, -width / 2);
  
  // Add holes
  holes.forEach(hole => {
    const { diameter, position_x = 0, position_y = 0 } = hole;
    const holePath = new THREE.Path();
    holePath.absarc(position_x, position_y, diameter / 2, 0, Math.PI * 2, true);
    shape.holes.push(holePath);
  });
  
  const extrudeSettings = {
    depth: thickness,
    bevelEnabled: false
  };
  
  const geometry = new THREE.ExtrudeGeometry(shape, extrudeSettings);
  geometry.rotateX(Math.PI / 2);
  geometry.translate(0, 0, -thickness / 2);
  
  const material = new THREE.MeshStandardMaterial({
    color: 0x00BCD4,
    roughness: 0.7,
    metalness: 0.2
  });
  
  return new THREE.Mesh(geometry, material);
}

/**
 * Generate a C-shaped clip
 * @param {Object} params - {outer_d, inner_d, thickness, gap_angle}
 */
export function generateClip(params) {
  const { outer_d, inner_d, thickness, gap_angle = 60 } = params;
  
  // Create C-shape (arc with gap)
  const shape = new THREE.Shape();
  
  const gapRad = (gap_angle * Math.PI) / 180;
  const startAngle = gapRad / 2;
  const endAngle = Math.PI * 2 - gapRad / 2;
  
  // Outer arc
  shape.absarc(0, 0, outer_d / 2, startAngle, endAngle, false);
  
  // Inner arc (hole)
  const hole = new THREE.Path();
  hole.absarc(0, 0, inner_d / 2, startAngle, endAngle, false);
  shape.holes.push(hole);
  
  const extrudeSettings = {
    depth: thickness,
    bevelEnabled: false
  };
  
  const geometry = new THREE.ExtrudeGeometry(shape, extrudeSettings);
  geometry.rotateX(Math.PI / 2);
  geometry.translate(0, 0, -thickness / 2);
  
  const material = new THREE.MeshStandardMaterial({
    color: 0xE91E63,
    roughness: 0.7,
    metalness: 0.2
  });
  
  return new THREE.Mesh(geometry, material);
}

/**
 * Main factory function - generates any part based on type
 */
export function generatePart(partType, parameters) {
  switch (partType) {
    case 'shim':
      return generateShim(parameters);
    case 'washer':
      return generateWasher(parameters);
    case 'l_bracket':
      return generateLBracket(parameters);
    case 'u_clamp':
      return generateUClamp(parameters);
    case 'face_plate':
      return generateFacePlate(parameters);
    case 'clip':
      return generateClip(parameters);
    default:
      throw new Error(`Unknown part type: ${partType}`);
  }
}

/**
 * Validate parameters against constraints
 */
export function validateParameters(partType, parameters, constraints) {
  const errors = [];
  
  // Check minimum thickness
  if (parameters.thickness < constraints.min_thickness) {
    errors.push(`Thickness must be >= ${constraints.min_thickness}mm`);
  }
  
  // Check hole diameters
  if (parameters.holes) {
    parameters.holes.forEach((hole, idx) => {
      if (hole.diameter < constraints.min_hole_diameter) {
        errors.push(`Hole ${idx + 1} diameter must be >= ${constraints.min_hole_diameter}mm`);
      }
    });
  }
  
  // Check maximum dimensions
  Object.entries(parameters).forEach(([key, value]) => {
    if (typeof value === 'number' && value > constraints.max_dimension) {
      errors.push(`${key} exceeds max dimension ${constraints.max_dimension}mm`);
    }
  });
  
  return { valid: errors.length === 0, errors };
}

