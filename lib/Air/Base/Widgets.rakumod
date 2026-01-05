unit module Widgets;

sub exports-air-base-widgets is export {<Widget LightDark>}

use Air::Functional :BASE-TAGS;
use Air::Component;
use Air::Base::Tags;

=head2 Air::Base::Widgets

=para Active tags that can be used anywhere to provide a nugget of UI behaviour, default should be a short word (or a single item) that can be used in Nav

role Widget does Component is export {}
#role Widget does Tag[Regular] is export {}

=head3 role LightDark does Tag[Regular] does Widget {...}

role LightDark does Widget is export {
    #| attribute 'show' may be set to 'icon'(default) or 'buttons'
    has $.show = 'icon';

    multi method HTML {
        given $!show {
            when 'buttons' { Safe.new:
                Q|
                    <div role="group">
                        <button class="contrast"  id="themeToggle">Toggle</button>
                        <button                   id="themeLight" >Light</button>
                        <button class="secondary" id="themeDark"  >Dark</button>
                        <button class="outline"   id="themeSystem">System</button>
                    </div>
                |;
            }
            when 'icon'    { Safe.new:
                Q|
                    <a style="font-variant-emoji: text" id ="sunIcon">&#9728;</a>
                    <a style="font-variant-emoji: text" id ="moonIcon">&#9790;</a>
                |;
            }
        }
    }

    method SCRIPT-HEAD {
        Q|
            (function () {
                const savedTheme = localStorage.getItem("theme");

                let theme;
                if (savedTheme) {
                    theme = savedTheme;
                } else {
                    theme = window.matchMedia("(prefers-color-scheme: dark)").matches
                        ? "dark"
                        : "light";
                }

                document.documentElement.setAttribute("data-theme", theme);
            })();
        |;
    }

    method SCRIPT {
        given $!show {
            when 'buttons' { self.buttons-script }
            when 'icon'    { self.icon-script    }
        }
    }

    method buttons-script {
        self.common ~

        Q|
            // Attach to button click
            document.getElementById("themeToggle").addEventListener("click", () => setTheme("toggle"));
            document.getElementById("themeDark").addEventListener("click", () => setTheme("dark"));
            document.getElementById("themeLight").addEventListener("click", () => setTheme("light"));
            document.getElementById("themeSystem").addEventListener("click", () => setTheme("system"));
        |;
    }

    method icon-script {
        Q|
            // Show/hide icons
            function updateIcons(theme) {
                if (theme === "dark") {
                    sunIcon.style.display = "none";
                    moonIcon.style.display = "block";
                } else {
                    sunIcon.style.display = "block";
                    moonIcon.style.display = "none";
                }
            }
        |

        ~ self.common ~

        Q|
            // Attach to icon click
            const sunIcon  = document.getElementById("sunIcon");
            const moonIcon = document.getElementById("moonIcon");

            document.getElementById("sunIcon").addEventListener("click", () => setTheme("dark"));
            document.getElementById("moonIcon").addEventListener("click", () => setTheme("light"));
        |;
    }

    method common {
        Q:to/END/
            function setTheme(mode) {
                const htmlElement = document.documentElement;
                let newTheme = mode;

                if (mode === "toggle") {
                    const currentTheme = htmlElement.getAttribute("data-theme") || "light";
                    newTheme = currentTheme === "dark" ? "light" : "dark";
                } else if (mode === "system") {
                    newTheme = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
                }

                htmlElement.setAttribute("data-theme", newTheme);
                localStorage.setItem("theme", newTheme); // Save theme to localStorage
                updateIcons(newTheme);
            }

            // update icons on page load
            document.addEventListener("DOMContentLoaded", () => {
                const theme = document.documentElement.getAttribute("data-theme");
                updateIcons(theme);
            });

            // Listen for system dark mode changes and update the theme dynamically
            window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
                setTheme("system"); // Follow system setting
            });
        END
    }
}

##### Functions Export #####

#| put in all the @components as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}
# viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing

my package EXPORT::DEFAULT {

    for exports-air-base-widgets() -> $name {

        OUR::{'&' ~ $name.lc} :=
            sub (*@a, *%h) {
                ::($name).new( |@a, |%h )
            }

    }
}

