import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Prism - SLMN Next",
  description: "A Next.js flagship starter for building beyond the default.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}