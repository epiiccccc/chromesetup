const d = new Date();
document.getElementById("date").textContent = new Intl.DateTimeFormat("nl-NL", {
  weekday: "long", day: "numeric", month: "long"
}).format(d);
