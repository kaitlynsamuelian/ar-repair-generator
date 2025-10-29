// AR measurement manager using device camera and point tracking
import * as THREE from 'three';

export class ARManager {
  constructor() {
    this.points = [];
    this.measurements = {};
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.markers = [];
    this.raycaster = new THREE.Raycaster();
    this.mouse = new THREE.Vector2();
    this.measurementLine = null;
    
    // For demo mode (when AR not available)
    this.demoMode = false;
    this.referencePlane = null;
  }

  /**
   * Initialize AR session
   * @param {HTMLElement} container - Container element
   * @param {string} preferredMode - 'auto', 'camera', or 'demo'
   */
  async initialize(container, preferredMode = 'auto') {
    try {
      // Check user preference
      if (preferredMode === 'demo') {
        this.demoMode = true;
      } else if (preferredMode === 'camera' || preferredMode === 'auto') {
        // Try to initialize camera (works on mobile and desktop)
        const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
        
        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        try {
          const videoConstraints = isMobile 
            ? { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } }
            : { width: { ideal: 1280 }, height: { ideal: 720 } };
          
          const stream = await navigator.mediaDevices.getUserMedia({
            video: videoConstraints
          });
          
          await this.initializeWithCamera(container, stream);
          this.demoMode = false;
          return true;
        } catch (cameraError) {
          // Store error for display
          this.cameraError = cameraError;
          
          // Show user-friendly error message
          let errorMsg = 'Camera blocked: ';
          if (cameraError.name === 'NotAllowedError') {
            errorMsg += 'Permission denied';
          } else if (cameraError.name === 'NotFoundError') {
            errorMsg += 'No camera found';
          } else if (cameraError.name === 'NotSupportedError' || cameraError.name === 'TypeError') {
            errorMsg += 'HTTPS required';
          } else {
            errorMsg += cameraError.message;
          }
          
          this.demoMode = true;
          this.cameraErrorMessage = errorMsg;
        }
        } else {
          this.demoMode = true;
        }
      }

      // DEMO MODE INITIALIZATION (only runs if in demo mode)
      if (!this.demoMode) {
        // Camera mode already initialized, exit here
        return true;
      }
      
      // Setup Three.js scene
      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x1a1a2e); // Dark blue-gray for better contrast

      // Setup camera
      this.camera = new THREE.PerspectiveCamera(
        75,
        window.innerWidth / window.innerHeight,
        0.1,
        1000
      );
      // Position camera to look down at the grid
      this.camera.position.set(0, 8, 8);
      this.camera.lookAt(0, 0, 0);

      // Setup renderer
      this.renderer = new THREE.WebGLRenderer({ 
        antialias: true,
        alpha: true 
      });
      this.renderer.setSize(window.innerWidth, window.innerHeight);
      this.renderer.setPixelRatio(window.devicePixelRatio);
      container.appendChild(this.renderer.domElement);

      // Add lighting
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
      this.scene.add(ambientLight);

      const directionalLight = new THREE.DirectionalLight(0xffffff, 0.6);
      directionalLight.position.set(5, 5, 5);
      this.scene.add(directionalLight);

      // Create reference plane for demo mode
      if (this.demoMode) {
        this.createReferencePlane();
      }

      // Setup event listeners
      this.setupEventListeners();

      // Start render loop
      this.animate();

      return true;
    } catch (error) {
      console.error('Failed to initialize AR:', error);
      return false;
    }
  }

  /**
   * Initialize with camera feed (AR mode)
   */
  async initializeWithCamera(container, stream) {
    // Create video element for camera feed
    const video = document.createElement('video');
    video.setAttribute('autoplay', '');
    video.setAttribute('playsinline', '');
    video.setAttribute('muted', '');
    video.style.position = 'fixed';
    video.style.top = '0';
    video.style.left = '0';
    video.style.width = '100%';
    video.style.height = '100%';
    video.style.objectFit = 'cover';
    video.style.zIndex = '0';
    video.style.pointerEvents = 'none';
    
    video.srcObject = stream;
    container.insertBefore(video, container.firstChild);
    
    await video.play();
    
    // Setup Three.js scene (transparent background to see camera)
    this.scene = new THREE.Scene();

    // Setup camera
    this.camera = new THREE.PerspectiveCamera(
      60,
      window.innerWidth / window.innerHeight,
      0.1,
      1000
    );
    this.camera.position.set(0, 0, 5);
    this.camera.lookAt(0, 0, 0);

    // Setup renderer with transparent background
    this.renderer = new THREE.WebGLRenderer({ 
      antialias: true,
      alpha: true // Transparent to see camera feed
    });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(window.devicePixelRatio);
    this.renderer.domElement.style.position = 'fixed';
    this.renderer.domElement.style.top = '0';
    this.renderer.domElement.style.left = '0';
    this.renderer.domElement.style.zIndex = '1';
    this.renderer.domElement.style.pointerEvents = 'auto';
    container.appendChild(this.renderer.domElement);

    // Add lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.8);
    this.scene.add(ambientLight);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.6);
    directionalLight.position.set(5, 5, 5);
    this.scene.add(directionalLight);

    // Create a virtual plane for ray casting - positioned directly in front of camera
    const geometry = new THREE.PlaneGeometry(10, 10);
    const material = new THREE.MeshBasicMaterial({
      color: 0x00ff88,
      transparent: true,
      opacity: 0.2, // Slightly visible so you can see where to tap
      side: THREE.DoubleSide
    });
    this.referencePlane = new THREE.Mesh(geometry, material);
    this.referencePlane.position.set(0, 0, 0); // Center it at origin
    this.scene.add(this.referencePlane);
    
    // Add a grid helper for visual reference in camera mode
    const gridHelper = new THREE.GridHelper(10, 10, 0x00ff88, 0x004400);
    gridHelper.material.opacity = 0.4;
    gridHelper.material.transparent = true;
    gridHelper.rotation.x = Math.PI / 2; // Lay flat facing camera
    this.scene.add(gridHelper);

    // Setup event listeners
    this.setupEventListeners();
    
    // Start render loop
    this.animate();
  }

  /**
   * Create a reference plane for measurements (demo mode)
   */
  createReferencePlane() {
    // Create a larger, more visible grid
    const geometry = new THREE.PlaneGeometry(15, 15, 30, 30);
    const material = new THREE.MeshBasicMaterial({
      color: 0x00ff88, // Bright green
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.8, // More opaque
      wireframe: true
    });
    this.referencePlane = new THREE.Mesh(geometry, material);
    this.referencePlane.rotation.x = -Math.PI / 2; // Lay flat
    this.scene.add(this.referencePlane);
    
    // Add a solid plane behind it for better visibility
    const solidGeometry = new THREE.PlaneGeometry(15, 15);
    const solidMaterial = new THREE.MeshBasicMaterial({
      color: 0x1a1a2e, // Match background but slightly lighter
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.3
    });
    const solidPlane = new THREE.Mesh(solidGeometry, solidMaterial);
    solidPlane.rotation.x = -Math.PI / 2;
    solidPlane.position.y = -0.02; // Slightly below the grid
    this.scene.add(solidPlane);
    
    // Add grid helper for better visibility
    const gridHelper = new THREE.GridHelper(15, 15, 0x00ff88, 0x004400);
    gridHelper.material.opacity = 0.4;
    gridHelper.material.transparent = true;
    this.scene.add(gridHelper);
  }

  /**
   * Setup event listeners for measurement
   */
  setupEventListeners() {
    window.addEventListener('resize', () => this.onWindowResize(), false);
    
    this.renderer.domElement.addEventListener('click', (event) => {
      this.onScreenTap(event);
    }, false);

    this.renderer.domElement.addEventListener('touchstart', (event) => {
      event.preventDefault(); // Prevent default touch behavior
      if (event.touches.length === 1) {
        this.onScreenTap(event.touches[0]);
      }
    }, { passive: false });
  }

  /**
   * Handle screen tap for measurement points
   */
  onScreenTap(event) {
    // Calculate mouse position in normalized device coordinates
    const rect = this.renderer.domElement.getBoundingClientRect();
    this.mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    this.mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

    // Raycast to find intersection
    this.raycaster.setFromCamera(this.mouse, this.camera);
    
    let intersection;
    if (this.referencePlane) {
      const intersects = this.raycaster.intersectObject(this.referencePlane);
      if (intersects.length > 0) {
        intersection = intersects[0].point;
      }
    }

    if (intersection) {
      this.addPoint(intersection);
    }
  }

  /**
   * Add a measurement point
   */
  addPoint(position) {
    // Limit to 2 points
    if (this.points.length >= 2) {
      return;
    }
    
    // Create visual marker
    const markerGeometry = new THREE.SphereGeometry(0.05, 16, 16);
    const markerMaterial = new THREE.MeshStandardMaterial({
      color: 0xFF5722,
      emissive: 0xFF5722,
      emissiveIntensity: 0.5
    });
    const marker = new THREE.Mesh(markerGeometry, markerMaterial);
    marker.position.copy(position);
    this.scene.add(marker);
    this.markers.push(marker);

    // Store point
    this.points.push(position.clone());

    // If we have 2 points, calculate distance
    if (this.points.length === 2) {
      this.calculateDistance();
    }

    // Trigger measurement event
    if (this.onMeasurementUpdate) {
      this.onMeasurementUpdate(this.measurements);
    }
  }

  /**
   * Calculate distance between two points
   */
  calculateDistance() {
    const p1 = this.points[0];
    const p2 = this.points[1];
    const distance = p1.distanceTo(p2);

    // Store measurement (in mm, assuming 1 unit = 10mm for demo)
    const distanceMM = Math.round(distance * 10 * 10) / 10; // Round to 1 decimal
    const measurementId = `dist_${Object.keys(this.measurements).length + 1}`;
    this.measurements[measurementId] = distanceMM;

    // Draw line between points
    this.drawMeasurementLine(p1, p2, distanceMM);
  }

  /**
   * Draw a line between measurement points
   */
  drawMeasurementLine(p1, p2, distance) {
    // Remove previous line
    if (this.measurementLine) {
      this.scene.remove(this.measurementLine);
    }

    // Create line
    const material = new THREE.LineBasicMaterial({ 
      color: 0x00FF00,
      linewidth: 2
    });
    const geometry = new THREE.BufferGeometry().setFromPoints([p1, p2]);
    this.measurementLine = new THREE.Line(geometry, material);
    this.scene.add(this.measurementLine);

    // Add label (using sprite with canvas texture)
    this.addDistanceLabel(p1, p2, distance);
  }

  /**
   * Add a text label showing distance
   */
  addDistanceLabel(p1, p2, distance) {
    const midpoint = new THREE.Vector3().lerpVectors(p1, p2, 0.5);
    
    // Create canvas for text
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');
    canvas.width = 256;
    canvas.height = 64;
    
    context.fillStyle = '#000000';
    context.fillRect(0, 0, canvas.width, canvas.height);
    context.fillStyle = '#00FF00';
    context.font = 'Bold 32px Arial';
    context.textAlign = 'center';
    context.fillText(`${distance}mm`, 128, 40);

    const texture = new THREE.CanvasTexture(canvas);
    const spriteMaterial = new THREE.SpriteMaterial({ map: texture });
    const sprite = new THREE.Sprite(spriteMaterial);
    sprite.position.copy(midpoint);
    sprite.scale.set(1, 0.25, 1);
    this.scene.add(sprite);
    this.markers.push(sprite);
  }

  /**
   * Clear all measurement points
   */
  clearPoints() {
    // Remove all markers
    this.markers.forEach(marker => {
      this.scene.remove(marker);
    });
    this.markers = [];
    
    // Remove measurement line
    if (this.measurementLine) {
      this.scene.remove(this.measurementLine);
      this.measurementLine = null;
    }

    // Clear data
    this.points = [];
    this.measurements = {};

    if (this.onMeasurementUpdate) {
      this.onMeasurementUpdate(this.measurements);
    }
  }

  /**
   * Get all measurements
   */
  getMeasurements() {
    return { ...this.measurements };
  }

  /**
   * Get measurements formatted for AI
   */
  getMeasurementsForAI() {
    const formatted = {};
    const keys = Object.keys(this.measurements);
    
    // Try to infer measurement types based on count
    if (keys.length >= 2) {
      formatted.length = this.measurements[keys[0]];
      formatted.width = this.measurements[keys[1]];
    }
    if (keys.length >= 3) {
      formatted.thickness = this.measurements[keys[2]];
    }
    if (keys.length >= 4) {
      formatted.hole_diameter = this.measurements[keys[3]];
    }

    return formatted;
  }

  /**
   * Handle window resize
   */
  onWindowResize() {
    this.camera.aspect = window.innerWidth / window.innerHeight;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(window.innerWidth, window.innerHeight);
  }

  /**
   * Animation loop
   */
  animate() {
    requestAnimationFrame(() => this.animate());
    
    // Rotate reference plane slowly for visual effect (demo mode only)
    if (this.referencePlane && this.demoMode) {
      this.referencePlane.rotation.z += 0.001;
    }

    this.renderer.render(this.scene, this.camera);
  }

  /**
   * Add a generated part to the scene
   */
  addPartToScene(partMesh) {
    // Remove previous part
    const existingPart = this.scene.getObjectByName('generated_part');
    if (existingPart) {
      this.scene.remove(existingPart);
    }

    // Add new part
    partMesh.name = 'generated_part';
    partMesh.position.set(0, 0, 0);
    
    // Scale to reasonable size for viewing
    const scale = 0.05; // Scale down for viewing
    partMesh.scale.set(scale, scale, scale);
    
    this.scene.add(partMesh);
    
    // Add rotation animation
    const animate = () => {
      if (partMesh.parent) {
        partMesh.rotation.y += 0.01;
        requestAnimationFrame(animate);
      }
    };
    animate();
  }

  /**
   * Cleanup
   */
  dispose() {
    if (this.renderer) {
      this.renderer.dispose();
      if (this.renderer.domElement.parentElement) {
        this.renderer.domElement.parentElement.removeChild(this.renderer.domElement);
      }
    }
  }
}

