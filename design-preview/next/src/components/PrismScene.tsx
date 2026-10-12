"use client";

import { useEffect, useRef } from "react";
import * as THREE from "three";

export default function PrismScene() {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    let renderer: THREE.WebGLRenderer;
    try {
      renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true, powerPreference: "low-power" });
    } catch (error) {
      console.error("Prism scene could not initialize WebGL.", error);
      const fallback = document.createElement("div");
      fallback.className = "scene-fallback";
      fallback.setAttribute("role", "status");
      const shape = document.createElement("span");
      shape.className = "fallback-shape";
      shape.setAttribute("aria-hidden", "true");
      const message = document.createElement("span");
      message.textContent = "3D preview is unavailable in this browser.";
      fallback.append(shape, message);
      container.appendChild(fallback);
      return () => fallback.remove();
    }

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(34, 1, 0.1, 40);
    camera.position.set(0, 0, 7);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
    renderer.setClearColor(0x000000, 0);
    container.appendChild(renderer.domElement);

    const core = new THREE.Group();
    scene.add(core);

    const crystalMaterial = new THREE.MeshPhysicalMaterial({
      color: 0x9de9ff,
      metalness: 0.48,
      roughness: 0.19,
      clearcoat: 1,
      clearcoatRoughness: 0.12,
      emissive: 0x123349,
      emissiveIntensity: 0.65,
      flatShading: true,
    });
    const crystal = new THREE.Mesh(new THREE.IcosahedronGeometry(1.12, 1), crystalMaterial);
    core.add(crystal);

    const innerCrystal = new THREE.Mesh(
      new THREE.OctahedronGeometry(0.69, 1),
      new THREE.MeshStandardMaterial({
        color: 0x83b6ff,
        metalness: 0.75,
        roughness: 0.23,
        flatShading: true,
      }),
    );
    innerCrystal.rotation.set(0.35, 0.2, 0.6);
    core.add(innerCrystal);

    const orbitMaterial = new THREE.MeshBasicMaterial({
      color: 0x8bdcf7,
      transparent: true,
      opacity: 0.36,
    });
    const orbits = [0, 1, 2].map((index) => {
      const orbit = new THREE.Mesh(new THREE.TorusGeometry(1.58 + index * 0.14, 0.006, 5, 112), orbitMaterial.clone());
      orbit.rotation.set(0.7 + index * 0.75, 0.25 + index * 0.38, index * 0.2);
      core.add(orbit);
      return orbit;
    });

    scene.add(new THREE.AmbientLight(0x9bc8ff, 1.25));
    const keyLight = new THREE.PointLight(0x80dcff, 28, 18);
    keyLight.position.set(-3, 3, 4);
    scene.add(keyLight);
    const rimLight = new THREE.PointLight(0x6baeff, 18, 16);
    rimLight.position.set(3, -2, -2);
    scene.add(rimLight);

    const resizeObserver = new ResizeObserver(() => {
      const { width, height } = container.getBoundingClientRect();
      if (width === 0 || height === 0) return;
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
      renderer.setSize(width, height, false);
      renderer.render(scene, camera);
    });
    resizeObserver.observe(container);

    const pointer = new THREE.Vector2();
    const onPointerMove = (event: PointerEvent) => {
      const bounds = container.getBoundingClientRect();
      pointer.set(
        ((event.clientX - bounds.left) / bounds.width) * 2 - 1,
        -((event.clientY - bounds.top) / bounds.height) * 2 + 1,
      );
    };
    const onPointerLeave = () => pointer.set(0, 0);
    container.addEventListener("pointermove", onPointerMove);
    container.addEventListener("pointerleave", onPointerLeave);

    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    let frame = 0;
    let elapsed = 0;
    let previousTime = 0;
    let visible = true;
    const observer = new IntersectionObserver(([entry]) => {
      visible = entry.isIntersecting;
      if (visible && !reducedMotion && frame === 0) frame = requestAnimationFrame(animate);
    });
    observer.observe(container);

    const animate = (time: number) => {
      frame = 0;
      if (!visible) return;
      const delta = previousTime === 0 ? 0 : Math.min((time - previousTime) / 1000, 0.04);
      previousTime = time;
      elapsed += delta;
      core.rotation.y += (pointer.x * 0.2 + Math.sin(elapsed * 0.32) * 0.08 - core.rotation.y) * 0.035;
      core.rotation.x += (-pointer.y * 0.13 + Math.sin(elapsed * 0.24) * 0.04 - core.rotation.x) * 0.035;
      innerCrystal.rotation.y += delta * 0.24;
      orbits.forEach((orbit, index) => {
        orbit.rotation.z += delta * (index % 2 === 0 ? 0.035 : -0.025);
      });
      renderer.render(scene, camera);
      frame = requestAnimationFrame(animate);
    };

    if (reducedMotion) {
      renderer.render(scene, camera);
    } else {
      frame = requestAnimationFrame(animate);
    }

    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
      resizeObserver.disconnect();
      container.removeEventListener("pointermove", onPointerMove);
      container.removeEventListener("pointerleave", onPointerLeave);
      scene.traverse((object) => {
        if (object instanceof THREE.Mesh) {
          object.geometry.dispose();
          const materials = Array.isArray(object.material) ? object.material : [object.material];
          materials.forEach((material) => material.dispose());
        }
      });
      renderer.dispose();
      renderer.domElement.remove();
    };
  }, []);

  return (
    <div className="prism-canvas" ref={containerRef} aria-label="Interactive faceted 3D prism">
    </div>
  );
}