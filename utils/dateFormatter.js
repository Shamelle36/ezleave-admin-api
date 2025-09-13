// utils/dateFormatter.js
export function formatPHDateTime(date) {
  if (!date) return null;

  const utcDate = new Date(date + "Z"); // force UTC → Manila

  const formattedDate = utcDate.toLocaleDateString("en-PH", {
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: "Asia/Manila",
  });

  const formattedTime = utcDate.toLocaleTimeString("en-PH", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
    timeZone: "Asia/Manila",
  });

  return `${formattedDate} | ${formattedTime}`;
}
