document.addEventListener("DOMContentLoaded", function () {
  const nav = document.querySelector("[data-glow-bottom-nav]");

  if (!nav) return;

  document.body.classList.add("has-glow-bottom-nav");

  const links = Array.from(nav.querySelectorAll(".glow-bottom-nav__link"));
  const indicator = nav.querySelector(".glow-bottom-nav__indicator");
  const list = nav.querySelector(".glow-bottom-nav__list");

  if (!links.length || !indicator || !list) return;

  list.style.setProperty("--glow-nav-count", String(links.length));

  function setActiveLink(activeLink) {
    const activeIndex = links.indexOf(activeLink);

    if (activeIndex < 0) return;

    links.forEach((link) => {
      link.classList.remove("is-active");
      link.setAttribute("aria-current", "false");
    });

    activeLink.classList.add("is-active");
    activeLink.setAttribute("aria-current", "page");

    indicator.style.transform = `translateX(${activeIndex * 100}%)`;
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
