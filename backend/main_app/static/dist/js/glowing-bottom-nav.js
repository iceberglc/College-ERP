document.addEventListener("DOMContentLoaded", function () {
  const nav = document.querySelector("[data-glow-bottom-nav]");

  if (!nav) return;

  document.body.classList.add("has-glow-bottom-nav");

  const list = nav.querySelector(".glow-bottom-nav__list");
  const links = Array.from(nav.querySelectorAll(".glow-bottom-nav__link"));

  if (!links.length || !list) return;

  list.style.setProperty("--glow-nav-count", String(links.length));

  function setActiveLink(activeLink) {
    if (!activeLink || !links.includes(activeLink)) return;

    links.forEach((link) => {
      link.classList.remove("is-active");
      link.removeAttribute("aria-current");
    });

    activeLink.classList.add("is-active");
    activeLink.setAttribute("aria-current", "page");
  }

  const serverActive = links.find((link) => link.classList.contains("is-active"));

  if (serverActive) {
    setActiveLink(serverActive);
    return;
  }

  const currentPath = window.location.pathname.replace(/\/+$/, "");

  const matchedLink =
    links.find((link) => {
      const linkPath = new URL(link.href, window.location.origin).pathname.replace(/\/+$/, "");
      return linkPath === currentPath;
    }) ||
    links.find((link) => {
      const linkPath = new URL(link.href, window.location.origin).pathname.replace(/\/+$/, "");
      return linkPath && linkPath !== "/" && currentPath.startsWith(linkPath);
    }) ||
    links[0];

  setActiveLink(matchedLink);
});
