// Global type declaration for Koalendar widget
interface Window {
  Koalendar: ((...args: unknown[]) => void) & {
    props?: unknown[];
  };
}
