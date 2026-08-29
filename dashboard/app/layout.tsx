import type { Metadata } from "next";
import Link from "next/link";
import CookieBanner from "@/components/CookieBanner";
import "./globals.css";

export const metadata: Metadata = {
  title: "Numeris – Lehrerportal",
  description: "Diagnostik-Dashboard für Lehrkräfte",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="de">
      <body className="bg-gray-50 text-gray-900 antialiased flex flex-col min-h-screen">
        <div className="flex-1">{children}</div>
        <footer className="border-t border-gray-200 bg-white px-6 py-4 text-xs text-gray-400 flex gap-6">
          <Link href="/impressum" className="hover:text-gray-700 transition-colors">
            Impressum
          </Link>
          <Link href="/wissenschaftliche-grundlagen" className="hover:text-gray-700 transition-colors">
            Wissenschaftliche Grundlagen
          </Link>
          <Link href="/datenschutz" className="hover:text-gray-700 transition-colors">
            Datenschutz
          </Link>
        </footer>
        <CookieBanner />
      </body>
    </html>
  );
}
