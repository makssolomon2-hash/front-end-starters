"use client";

import { useEffect } from "react";
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import PrismScene from "@/components/PrismScene";

const technologies = [
  {
    number: "01",
    name: "Next.js",
    detail: "App Router",
    href: "https://nextjs.org/docs/app",
    tone: "electric",
  },
  {
    number: "02",
    name: "React",
    detail: "UI foundation",
    href: "https://react.dev",
    tone: "cyan",
  },
  {
    number: "03",
    name: "TypeScript",
    detail: "Typed by design",
    href: "https://www.typescriptlang.org/docs/",
    tone: "blue",
  },
  {
    number: "04",
    name: "Tailwind CSS",
    detail: "Version 4",
    href: "https://tailwindcss.com/docs",
    tone: "teal",
  },
  {
    number: "05",
    name: "GSAP",
    detail: "Motion system",
    href: "https://gsap.com/docs/",
    tone: "green",
  },
  {
    number: "06",
    name: "Three.js",
    detail: "Realtime canvas",
    href: "https://threejs.org/docs/",
    tone: "silver",
  },
];

export default function StarterExperience() {
  useEffect(() => {
    gsap.registerPlugin(ScrollTrigger);
    const context = gsap.context(() => {
      const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      if (reducedMotion) return;

      gsap.from("[data-hero-reveal]", {
        y: 22,
        opacity: 0,
        duration: 0.85,
        stagger: 0.1,
        ease: "power3.out",
      });

      gsap.utils.toArray<HTMLElement>("[data-stack-card]").forEach((card, index) => {
        gsap.from(card, {
          y: 28,
          opacity: 0,
          duration: 0.7,
          delay: (index % 3) * 0.08,
          ease: "power2.out",
          scrollTrigger: {
            trigger: card,
            start: "top 88%",
            once: true,
          },
        });
      });
    });

    return () => context.revert();
  }, []);

  return (
    <main className="experience-shell">
      <div className="ambient ambient-one" aria-hidden="true" />
      <div className="ambient ambient-two" aria-hidden="true" />
      <div className="ambient ambient-three" aria-hidden="true" />
      <div className="particle-field particle-field-one" aria-hidden="true" />
      <div className="particle-field particle-field-two" aria-hidden="true" />
      <div className="grain" aria-hidden="true" />

      <header className="topbar">
        <a className="wordmark" href="#top" aria-label="Prism home">
          <span className="wordmark-glyph" aria-hidden="true">S</span>
          <span>SLMN<span className="wordmark-separator">/</span>NEXT</span>
        </a>
        <a className="topbar-link" href="#stack">
          Explore the stack
          <svg className="interface-icon" aria-hidden="true" focusable="false" viewBox="0 0 16 16">
            <path d="m4 4 8 8M6 12h6V6" />
          </svg>
        </a>
      </header>

      <section className="hero" id="top" aria-labelledby="hero-title">
        <div className="hero-copy">
          <p className="eyebrow" data-hero-reveal>
            <span className="status-dot" /> A sharper starting point
          </p>
          <h1 id="hero-title" data-hero-reveal>
            Build beyond
            <span>the default.</span>
          </h1>
          <p className="hero-description" data-hero-reveal>
            A considered canvas for ambitious ideas. Modern foundations,
            expressive motion, and room to make it yours.
          </p>
          <div className="hero-actions" data-hero-reveal>
            <a className="primary-link" href="#stack">
              Explore the toolkit
              <svg className="interface-icon" aria-hidden="true" focusable="false" viewBox="0 0 16 16">
                <path d="M4 12 12 4M5 4h7v7" />
              </svg>
            </a>
            <span className="release-note">APP ROUTER <i /> TYPESCRIPT</span>
          </div>
        </div>

        <div className="visual-wrap" data-hero-reveal>
          <div className="visual-card">
            <div className="visual-grid" aria-hidden="true" />
            <div className="visual-topline">
              <span>FIG. 01 / PRISM ENGINE</span>
              <span className="live-indicator"><i /> LIVE</span>
            </div>
            <PrismScene />
            <div className="visual-caption">
              <span className="caption-index">01</span>
              <div>
                <strong>Form in motion</strong>
                <span>Move your pointer to explore</span>
              </div>
              <span className="caption-crosshair" aria-hidden="true">+</span>
            </div>
          </div>
          <span className="orbit-label orbit-label-one">REALTIME / 3D</span>
          <span className="orbit-label orbit-label-two">INTERACTIVE BY DESIGN</span>
        </div>

        <div className="hero-foot" aria-hidden="true">
          <span>DESIGNED TO DISAPPEAR WHEN YOU ARE READY</span>
          <span className="scroll-hint">
            SCROLL TO EXPLORE
            <svg className="interface-icon" focusable="false" viewBox="0 0 16 16">
              <path d="M8 3v10m-4-4 4 4 4-4" />
            </svg>
          </span>
        </div>
      </section>

      <section className="stack-section" id="stack" aria-labelledby="stack-title">
        <div className="section-heading">
          <div>
            <p className="eyebrow"><span className="section-index">01</span> THE FOUNDATION</p>
            <h2 id="stack-title">Every layer, <span>in sync.</span></h2>
          </div>
          <p className="section-intro">
            A focused set of tools for a fast, expressive, production-ready
            front end. Each one has a place here.
          </p>
        </div>

        <div className="stack-grid">
          {technologies.map((technology) => (
            <a
              className={`stack-card stack-card-${technology.tone}`}
              data-stack-card
              href={technology.href}
              key={technology.name}
              rel="noreferrer"
              target="_blank"
            >
              <div className="stack-card-top">
                <span className="stack-number">{technology.number}</span>
                <svg className="stack-arrow" aria-hidden="true" focusable="false" viewBox="0 0 16 16">
                  <path d="M4 12 12 4M5 4h7v7" />
                </svg>
              </div>
              <div className="stack-card-bottom">
                <span className="stack-orb" aria-hidden="true" />
                <div>
                  <h3>{technology.name}</h3>
                  <p>{technology.detail}</p>
                </div>
              </div>
            </a>
          ))}
        </div>
      </section>

      <footer className="footer">
        <a className="wordmark footer-wordmark" href="#top">
          <span className="wordmark-glyph" aria-hidden="true">S</span>
          <span>SLMN<span className="wordmark-separator">/</span>NEXT</span>
        </a>
        <p>Your canvas. Your call.</p>
        <span className="footer-note">REMOVE THE DEMO. KEEP THE FOUNDATION.</span>
      </footer>
    </main>
  );
}