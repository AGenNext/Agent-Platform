import './globals.css';

export const metadata = {
  title: 'AGenNext Internal Agent Console',
  description: 'Internal hPanel-style control panel for AGenNext operations',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
