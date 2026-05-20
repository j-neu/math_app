"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

const CONSENT_KEY = "cookie_consent_v1";

export default function CookieBanner() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (!localStorage.getItem(CONSENT_KEY)) {
      setVisible(true);
    }
  }, []);

  function accept() {
    localStorage.setItem(CONSENT_KEY, "accepted");
    setVisible(false);
  }

  if (!visible) return null;

  return (
    <div className="fixed bottom-0 left-0 right-0 z-50 bg-white border-t border-gray-200 shadow-lg">
      <div className="max-w-5xl mx-auto px-6 py-4 flex flex-col sm:flex-row items-start sm:items-center gap-4">
        <p className="text-sm text-gray-700 flex-1">
          Diese Anwendung verwendet ausschließlich technisch notwendige Cookies
          für die Anmeldung. Keine Tracking- oder Analyse-Cookies.{" "}
          <Link href="/datenschutz" className="underline hover:text-gray-900">
            Datenschutzerklärung
          </Link>
        </p>
        <button
          onClick={accept}
          className="shrink-0 bg-[#154761] text-white text-sm px-4 py-2 rounded hover:bg-[#1a5a7a] transition-colors"
        >
          Verstanden
        </button>
      </div>
    </div>
  );
}
