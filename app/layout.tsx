import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "WorkProof AI — Work verified. Payments tracked.", description: "Job management, work evidence, customer approvals and payment tracking for Indian service businesses." };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
