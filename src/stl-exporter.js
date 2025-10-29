// STL Export functionality
import * as THREE from 'three';

/**
 * Export Three.js mesh to STL format
 * Based on THREE.STLExporter but simplified and embedded
 */
export class STLExporter {
  /**
   * Export mesh to STL binary format
   * @param {THREE.Mesh} mesh - The mesh to export
   * @returns {ArrayBuffer} - STL file data
   */
  exportBinary(mesh) {
    const geometry = mesh.geometry;
    
    // Ensure geometry has position attribute
    if (!geometry.attributes.position) {
      throw new Error('Geometry must have position attribute');
    }

    // Get triangles
    const vertices = geometry.attributes.position.array;
    const indices = geometry.index ? geometry.index.array : null;
    
    let triangleCount;
    if (indices) {
      triangleCount = indices.length / 3;
    } else {
      triangleCount = vertices.length / 9;
    }

    // STL binary format:
    // 80 bytes header
    // 4 bytes triangle count
    // For each triangle:
    //   - 12 bytes normal (3 floats)
    //   - 36 bytes vertices (3 vertices × 3 floats × 4 bytes)
    //   - 2 bytes attribute count
    const bufferSize = 84 + (triangleCount * 50);
    const buffer = new ArrayBuffer(bufferSize);
    const view = new DataView(buffer);

    // Write header (80 bytes)
    const header = 'STL Binary exported from AR Repair Generator';
    for (let i = 0; i < 80; i++) {
      view.setUint8(i, i < header.length ? header.charCodeAt(i) : 0);
    }

    // Write triangle count
    view.setUint32(80, triangleCount, true);

    // Apply mesh transformations
    const matrix = mesh.matrixWorld;
    const normal = new THREE.Vector3();
    const v1 = new THREE.Vector3();
    const v2 = new THREE.Vector3();
    const v3 = new THREE.Vector3();

    let offset = 84;

    // Write triangles
    for (let i = 0; i < triangleCount; i++) {
      let i1, i2, i3;
      
      if (indices) {
        i1 = indices[i * 3];
        i2 = indices[i * 3 + 1];
        i3 = indices[i * 3 + 2];
      } else {
        i1 = i * 3;
        i2 = i * 3 + 1;
        i3 = i * 3 + 2;
      }

      // Get vertices
      v1.fromArray(vertices, i1 * 3);
      v2.fromArray(vertices, i2 * 3);
      v3.fromArray(vertices, i3 * 3);

      // Apply transformation
      v1.applyMatrix4(matrix);
      v2.applyMatrix4(matrix);
      v3.applyMatrix4(matrix);

      // Calculate normal
      const edge1 = v2.clone().sub(v1);
      const edge2 = v3.clone().sub(v1);
      normal.crossVectors(edge1, edge2).normalize();

      // Write normal
      view.setFloat32(offset, normal.x, true);
      view.setFloat32(offset + 4, normal.y, true);
      view.setFloat32(offset + 8, normal.z, true);
      offset += 12;

      // Write vertices
      view.setFloat32(offset, v1.x, true);
      view.setFloat32(offset + 4, v1.y, true);
      view.setFloat32(offset + 8, v1.z, true);
      offset += 12;

      view.setFloat32(offset, v2.x, true);
      view.setFloat32(offset + 4, v2.y, true);
      view.setFloat32(offset + 8, v2.z, true);
      offset += 12;

      view.setFloat32(offset, v3.x, true);
      view.setFloat32(offset + 4, v3.y, true);
      view.setFloat32(offset + 8, v3.z, true);
      offset += 12;

      // Write attribute byte count (unused)
      view.setUint16(offset, 0, true);
      offset += 2;
    }

    return buffer;
  }

  /**
   * Export mesh to STL ASCII format (human-readable)
   * @param {THREE.Mesh} mesh - The mesh to export
   * @returns {string} - STL file content as string
   */
  exportASCII(mesh) {
    const geometry = mesh.geometry;
    
    if (!geometry.attributes.position) {
      throw new Error('Geometry must have position attribute');
    }

    const vertices = geometry.attributes.position.array;
    const indices = geometry.index ? geometry.index.array : null;
    
    let triangleCount;
    if (indices) {
      triangleCount = indices.length / 3;
    } else {
      triangleCount = vertices.length / 9;
    }

    // Apply mesh transformations
    const matrix = mesh.matrixWorld;
    const normal = new THREE.Vector3();
    const v1 = new THREE.Vector3();
    const v2 = new THREE.Vector3();
    const v3 = new THREE.Vector3();

    let output = 'solid exported\n';

    // Write triangles
    for (let i = 0; i < triangleCount; i++) {
      let i1, i2, i3;
      
      if (indices) {
        i1 = indices[i * 3];
        i2 = indices[i * 3 + 1];
        i3 = indices[i * 3 + 2];
      } else {
        i1 = i * 3;
        i2 = i * 3 + 1;
        i3 = i * 3 + 2;
      }

      // Get vertices
      v1.fromArray(vertices, i1 * 3);
      v2.fromArray(vertices, i2 * 3);
      v3.fromArray(vertices, i3 * 3);

      // Apply transformation
      v1.applyMatrix4(matrix);
      v2.applyMatrix4(matrix);
      v3.applyMatrix4(matrix);

      // Calculate normal
      const edge1 = v2.clone().sub(v1);
      const edge2 = v3.clone().sub(v1);
      normal.crossVectors(edge1, edge2).normalize();

      output += `  facet normal ${normal.x.toExponential()} ${normal.y.toExponential()} ${normal.z.toExponential()}\n`;
      output += '    outer loop\n';
      output += `      vertex ${v1.x.toExponential()} ${v1.y.toExponential()} ${v1.z.toExponential()}\n`;
      output += `      vertex ${v2.x.toExponential()} ${v2.y.toExponential()} ${v2.z.toExponential()}\n`;
      output += `      vertex ${v3.x.toExponential()} ${v3.y.toExponential()} ${v3.z.toExponential()}\n`;
      output += '    endloop\n';
      output += '  endfacet\n';
    }

    output += 'endsolid exported\n';
    return output;
  }

  /**
   * Download STL file
   * @param {THREE.Mesh} mesh - The mesh to export
   * @param {string} filename - Output filename
   * @param {boolean} binary - Use binary format (default true)
   */
  download(mesh, filename = 'part.stl', binary = true) {
    let blob;
    
    if (binary) {
      const data = this.exportBinary(mesh);
      blob = new Blob([data], { type: 'application/octet-stream' });
    } else {
      const data = this.exportASCII(mesh);
      blob = new Blob([data], { type: 'text/plain' });
    }

    // Create download link
    const link = document.createElement('a');
    link.style.display = 'none';
    document.body.appendChild(link);
    
    link.href = URL.createObjectURL(blob);
    link.download = filename;
    link.click();
    
    // Cleanup
    document.body.removeChild(link);
    URL.revokeObjectURL(link.href);
  }
}

/**
 * Helper function to prepare mesh for export
 * Ensures geometry is properly computed
 */
export function prepareMeshForExport(mesh) {
  // Update matrix world
  mesh.updateMatrixWorld(true);
  
  // Ensure geometry is not indexed for simpler export
  const geometry = mesh.geometry;
  if (geometry.index) {
    // Convert indexed geometry to non-indexed
    const nonIndexedGeometry = geometry.toNonIndexed();
    mesh.geometry = nonIndexedGeometry;
  }
  
  // Compute normals if not present
  if (!geometry.attributes.normal) {
    geometry.computeVertexNormals();
  }
  
  return mesh;
}

