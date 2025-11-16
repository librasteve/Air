unit module Widgets;

sub exports-air-base-widgets is export {<Widget LightDark>}

use Air::Functional :BASE-TAGS;
use Air::Base::Tags;

=head2 Air::Base::Widgets

=para Active tags that can be used anywhere to provide a nugget of UI behaviour, default should be a short word (or a single item) that can be used in Nav

role Widget does Tag[Regular] is export {}

=head3 role LightDark does Tag[Regular] does Widget {...}

role LightDark does Widget is export {
    #| attribute 'show' may be set to 'icon'(default) or 'buttons'
    multi method HTML {
        my $show = self.attrs<show> // 'icon';
        given $show {
            when 'buttons' { Safe.new: self.buttons }
            when 'icon'    { Safe.new: self.icon    }
        }
    }

    method buttons {
        Q|
        <div role="group">
            <button class="contrast"  id="themeToggle">Toggle</button>
            <button                   id="themeLight" >Light</button>
            <button class="secondary" id="themeDark"  >Dark</button>
            <button class="outline"   id="themeSystem">System</button>
        </div>
        <script>
        |

            ~ self.common ~

            Q|
            // Attach to a button click
            document.getElementById("themeToggle").addEventListener("click", () => setTheme("toggle"));
            document.getElementById("themeDark").addEventListener("click", () => setTheme("dark"));
            document.getElementById("themeLight").addEventListener("click", () => setTheme("light"));
            document.getElementById("themeSystem").addEventListener("click", () => setTheme("system"));
        </script>
        |;
    }

    method icon {
        Q|
        <a style="font-variant-emoji: text" id ="sunIcon">&#9728;</a>
        <a style="font-variant-emoji: text" id ="moonIcon">&#9790;</a>
        <script>
            // Function to show/hide icons
            function updateIcons(theme) {
                if (theme === "dark") {
                    sunIcon.style.display = "none"; // Hide sun
                    moonIcon.style.display = "block"; // Show moon
                } else {
                    sunIcon.style.display = "block"; // Show sun
                    moonIcon.style.display = "none"; // Hide moon
                }
            }
        |

            ~ self.common ~

            Q|
            const sunIcon = document.getElementById("sunIcon");
            const moonIcon = document.getElementById("moonIcon");

            // Attach to a icon click
            document.getElementById("sunIcon").addEventListener("click", () => setTheme("dark"));
            document.getElementById("moonIcon").addEventListener("click", () => setTheme("light"));
        </script>
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

            // select theme on page load
            document.addEventListener("DOMContentLoaded", () => {
                const savedTheme = localStorage.getItem("theme");
                const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
                const initialTheme = savedTheme ?? (systemPrefersDark ? "dark" : "light");

                updateIcons(initialTheme);
                document.documentElement.setAttribute("data-theme", initialTheme);
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

