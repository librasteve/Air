unit module Elements;

sub exports-air-base-elements is export {<Table Grid Flexbox Dashboard Box Tab Tabs Dialog Lightbox Markdown>}

use Air::Functional :TEMPIN2;
use Air::Component;
use Air::Base::Tags;

=head2 Air::Base::Elements

=para The set of layout and functional web components that Air provides for use in web pages.

=para  The Air roadmap is to provide a full set of pre-styled tags as defined in the Pico L<docs|https://picocss.com/docs>. Did we say that Air::Base implements Pico CSS?

=head2 Layout Elements

=head3 role Table does Component is export

role Table     does Component is export {

    =para Attrs thead, tbody and tfoot can each be a 1D [values] or 2D Array [[values],] that iterates to row and columns or a Tag|Component - if the latter then they are just rendered via their .HTML method. This allow for single- and multi-row thead and tfoot.

    =para Table applies col and row header tags <th></th> as required for Pico styles.

    #| optional (ie tbody-attrs only is ok)
    has $.tbody is rw;
    #| explicitly specify attrs on tbody
    has %.tbody-attrs;
    #| optional
    has $.thead;
    #| optional
    has $.tfoot;
    #| class for table
    has $.class;

    #| .new positional takes tbody unless passed as attr
    multi method new(*@tbody, *%h) {
        if %h<tbody> {
            self.bless: |%h
        } else {
            self.bless: :@tbody, |%h
        }
    }

    sub do-row(@row, :$head) {
        tr do for @row.kv -> $col, $cell {
            given    	$col, $head {
                when   	  *,    *.so  { th $cell, :scope<col> }
                when   	  0,    *     { th $cell, :scope<row> }
                default               { td $cell }
            }
        }
    }

    # parts as objects - single tbody
    multi sub do-part($part where Tag|Taggable|Markup) {
        $part
    }
    # parts as objects - list of eg tr's
    multi sub do-part(@part where .all ~~ Tag|Taggable|Markup) {
        |@part
    }
    # parts as values - 2D array
    multi sub do-part(@part where .all ~~ Positional, :$head) {
        if @part.elems == 1 {   # got a 2D with one element
            nextwith @part[0]
        }
        do for @part -> @row {
            do-row(@row, :$head)
        }
    }
    # parts as values - 1D array
    multi sub do-part(@part, :$head) {
        do-row(@part, :$head)
    }


    multi method HTML {
        table |%(:$!class if $!class), [
            thead do-part($.thead, :head) with $.thead;
            tbody |%.tbody-attrs,
                do-part($.tbody) with $.tbody;
            tfoot do-part($.tfoot) with $.tfoot;
        ]
    }
}

=head3 role Grid does Component is export

role Grid      does Component is export {
    #| list of items to populate grid
    has @.items;

    has $.cols = 1;
    has $.grid-template-columns = "repeat($!cols, 1fr)";
    has $.rows = 1;
    has $.grid-template-rows    = "repeat($!rows, 1fr)";
    has $.gap = 0;
    has $.direction = 'ltr';


    #| .new positional takes @items
    multi method new(*@items, *%h) {
        self.bless:  :@items, |%h;
    }

    # optional grid style from https://cssgrid-generator.netlify.app/
    # fixme load Grid.new as standard (like Nav.new)
    method style {
        my $str = q:to/END/;
        <style>
            #%HTML-ID% {
                display: grid;
                grid-template-columns: %GTC%;
                grid-template-rows: %GTR%;
                gap: %GAP%em;
                direction: %DIR%;
            }

            @media (max-width: 1024px) {
                #%HTML-ID% {
                    display: flex;
                    flex-direction: column-reverse;

                    gap: 1px;
                }
            }
        </style>
        END

        $str ~~ s:g/'%HTML-ID%'/$.html-id/;
        $str ~~ s:g/'%GTC%'/$!grid-template-columns/;
        $str ~~ s:g/'%GTR%'/$!grid-template-rows/;
        $str ~~ s:g/'%GAP%'/$!gap/;
        $str ~~ s:g/'%DIR%'/$!direction/;
        $str
    }

    multi method HTML {
        $.style ~
            div :id($.html-id), @!items;
    }
}

=head3 role Flexbox does Component is export

role Flexbox   does Component is export {
    #| list of items to populate grid,
    has @.items;
    #| flex-direction (default row)
    has $.direction = 'row';
    #| gap between items in em (default 1)
    has $.gap = 1;

    #| .new positional takes @items
    multi method new(*@items, *%h) {
        self.bless:  :@items, |%h;
    }

    method style {
        my $str = q:to/END/;
        <style>
            #%HTML-ID% {
                display: flex;
                flex-direction: %DIRECTION%; /* column row */
                justify-content: center;  /* centers horizontally */
                gap: %GAP%em;
            }

            /* Responsive layout - makes a one column layout instead of a two-column layout */
            @media (max-width: 768px) {
                #%HTML-ID% {
                    flex-direction: column;
                    gap: 0;
                }
            }
        </style>
        END

        $str ~~ s:g/'%HTML-ID%'/$.html-id/;
        $str ~~ s:g/'%DIRECTION%'/$!direction/;
        $str ~~ s:g/'%GAP%'/$!gap/;
        $str
    }

    multi method HTML {
        $.style ~
            div :id($.html-id), @!items;
    }
}

=head3 role Dashboard does Component is export

role Dashboard does Component is export {
    has @.inners;
    has %.attrs;

    multi method new(*@inners, *%attrs) {
        self.bless:  :@inners, |%attrs;
    }

    # this emits a dashboard tag
    multi method HTML {
        do-regular-tag( 'dashboard', @.inners, |%.attrs )
    }

    method STYLE {
        Q:to/END/;
        dashboard {
          display: flex;
          flex-wrap: wrap;
          gap: 1rem;
        }
        END
    }
}

=head3 role Box does Component is export

role Box       does Component is export {
    #| specify sequential order of box
    has Int $.order;# is required;

    has @.inners;
    has %.attrs;

    multi method new(*@inners, *%attrs) {
        self.bless:  :@inners, |%attrs;
    }

    # this emits an article tag with pico style
    # Keep text ltr even when grid direction rtl
    multi method HTML {
        my %attrs  = |%.attrs, :style("direction:ltr;");

        if $.order {
            %attrs  = |%.attrs, :style("order: $.order;");
        }

        do-regular-tag( 'article', @.inners, |%attrs )
    }

    method STYLE {
        Q:to/END/;
        dashboard > article {
          display: flex;
          align-items: center;
          flex-direction: column;

          /* Responsive sizing */
          flex: 1 1 600px;
          //min-width: 600px;
          max-width: 800px;
        }
        END
    }
}

=head3 role Tab does Tag[Regular] {...}

role Tab       does Component is export {
    has @.inners;
    has %.attrs;

    multi method new(*@inners, *%attrs) {
        self.bless:  :@inners, |%attrs;
    }

    method HTML {
        my %attrs = |%.attrs, :class<tab>, :align<left>;
        do-regular-tag( 'div', @.inners, |%attrs )
    }
}

=head3 subset TabItem of Pair where .value ~~ Tab;

subset TabItem of Pair where .value ~~ Tab;

=head3 role Tabs does Component is export

#| Tabs does Component is export to control multiple tabs
role Tabs      does Component is export {
    has $!loaded = 0;

    #| Tabs take two attrs for menu alignment
    #| The default is to align="left" and to not adapt to media width
    #| $.align-menu <left right center> sets the overall preference
    has Str $.align-menu = 'left';
    #| $.adapt-menu <'' left right center> sets the value for small viewport
    has Str $.adapt-menu = '';

    #| list of tab sections
    has TabItem @.items;

    #| .new positional takes @items
    multi method new(*@items, *%h) {
        self.bless:  :@items, |%h;
    }

    #| makes routes for Tabs
    #| must be called from within a Cro route block
    method make-routes() {
        return if $!loaded++;
        do for self.items.map: *.kv -> ($name, $target) {
            given $target {
                my &new-method = method {$target.?HTML};
                trait_mod:<is>(&new-method, :controller{:$name, :returns-html});
                self.^add_method($name, &new-method);
            }
        }
    }

    method tab-content { $.html-id ~ '-content' }

    #viz. https://chatgpt.com/share/68708997-9b18-8009-8e44-14e127fc4e8f
    method tab-items {

        my $i = 1; my %attrs;
        do for @.items.map: *.kv -> ($name, $target) {

            given $target {
                %attrs<class> = ($i==1) ?? 'active' !!'';

                li |%attrs,
                    a(
                    :hx-get("$.url-path/$name"),
                        :hx-target("#$.tab-content"),
                        :data-value($i++),
                        Safe.new: $name,
                    )
            }

        }
    }

    method HTML {
        method load-path  { $.url-path ~ '/' ~ @.items[0].key }

        div :class<tabs>, [
            nav :class<tab-menu>,
                ul :class<tab-links>, self.tab-items;
            div :id($.tab-content), @.items[0].value;
        ]
    }

    method STYLE {
        my $css = q:to/END/;
        .tab-menu {
            display: block;
            justify-content: %ALIGN-MENU%;
        }
        .tab-links {
            display: block;
        }
        .tab-links > li.active > a {
            text-decoration: underline;
        }

        @media (max-width: 768px) {
            .tab-menu {
                text-align: %ADAPT-MENU%;
            }
            .tab-links > * {
                padding-top: 0;
                padding-bottom:1em;
            }
        }
        END

        $.adapt-menu = $.adapt-menu ?? 'center' !! $.align-menu;

        $css ~~ s:g/'%ALIGN-MENU%'/$.align-menu/;
        $css ~~ s:g/'%ADAPT-MENU%'/$.adapt-menu/;
        $css
    }

    method SCRIPT {
        q:to/END/;
        function setupTabLinks() {
            const links = document.querySelectorAll('.tab-links > *');
            const hiddenInput = document.getElementById('selectedOption');
            const display = document.getElementById('selectedDisplay');

            links.forEach(link => {
                link.addEventListener('click', function (e) {
                    e.preventDefault();

                    links.forEach(l => l.classList.remove('active'));

                    this.classList.add('active');

                    const value = this.getAttribute('data-value');
                    if (hiddenInput) hiddenInput.value = value;
                    if (display) display.textContent = `Selected: ${this.textContent}`;
                });
            });
        }

        // Run on initial load
        document.addEventListener('DOMContentLoaded', setupTabLinks);

        // Re-run after HTMX swaps in new content
        document.body.addEventListener('htmx:afterSwap', setupTabLinks);
        END
    }
}

=head2 Action Elements

=head3 role Dialog does Component is export

# fixme not working yet
role Dialog     does Component is export {
    method SCRIPT {
        q:to/END/;
/*
* Modal
*
* Pico.css - https://picocss.com
* Copyright 2019-2024 - Licensed under MIT
*/

// Config
const isOpenClass = "modal-is-open";
const openingClass = "modal-is-opening";
const closingClass = "modal-is-closing";
const scrollbarWidthCssVar = "--pico-scrollbar-width";
const animationDuration = 1000; // ms
let visibleModal = null;

// Toggle modal
const toggleModal = (event) => {
  event.preventDefault();
  const modal = document.getElementById(event.currentTarget.dataset.target);
  if (!modal) return;
  modal && (modal.open ? closeModal(modal) : openModal(modal));
};

// Open modal
const openModal = (modal) => {
  const { documentElement: html } = document;
  const scrollbarWidth = getScrollbarWidth();
  if (scrollbarWidth) {
    html.style.setProperty(scrollbarWidthCssVar, `${scrollbarWidth}px`);
  }
  html.classList.add(isOpenClass, openingClass);
  setTimeout(() => {
    visibleModal = modal;
    html.classList.remove(openingClass);
  }, animationDuration);
  modal.showModal();
};

// Close modal
const closeModal = (modal) => {
  visibleModal = null;
  const { documentElement: html } = document;
  html.classList.add(closingClass);
  setTimeout(() => {
    html.classList.remove(closingClass, isOpenClass);
    html.style.removeProperty(scrollbarWidthCssVar);
    modal.close();
  }, animationDuration);
};

// Close with a click outside
document.addEventListener("click", (event) => {
  if (visibleModal === null) return;
  const modalContent = visibleModal.querySelector("article");
  const isClickInside = modalContent.contains(event.target);
  !isClickInside && closeModal(visibleModal);
});

// Close with Esc key
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && visibleModal) {
    closeModal(visibleModal);
  }
});

// Get scrollbar width
const getScrollbarWidth = () => {
  const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth;
  return scrollbarWidth;
};

// Is scrollbar visible
const isScrollbarVisible = () => {
  return document.body.scrollHeight > screen.height;
};
END
    }

    method HTML {
        div [
            Safe.new: '<button class="contrast" data-target="modal-example" onclick="toggleModal(event)">Launch demo modal</button>';
            Safe.new: q:to/MODAL/;
            <dialog id="modal-example">
                <article>
                <header>
                <button aria-label="Close" rel="prev" data-target="modal-example" onclick="toggleModal(event)"></button>
                  <h3>Confirm your action!</h3>
                </header>
                <p>
                  Cras sit amet maximus risus. Pellentesque sodales odio sit amet augue finibus
                  pellentesque. Nullam finibus risus non semper euismod.
                </p>
                <footer>
                  <button role="button" class="secondary" data-target="modal-example" onclick="toggleModal(event)">
                    Cancel</button><button autofocus="" data-target="modal-example" onclick="toggleModal(event)">
                    Confirm
                  </button>
                </footer>
              </article>
            </dialog>
            MODAL
        ]
    }
}

=head3 role Lightbox does Component is export

role Lightbox     does Component is export {
    has $!loaded;

    #| unique lightbox label
    has Str    $.label = 'open';
    has Button $.button;

    #| can be provided with attrs
    has %.attrs is rw;

    #| can be provided with inners
    has @.inners;

    #| ok to call .new with @inners as Positional
    multi method new(*@inners, *%attrs) {
        self.bless:  :@inners, :%attrs
    }

    method HTML {
        if @!inners[0] ~~ Button && ! $!loaded++ {
            $!button = @!inners.shift;
        }

        div [
            if $!button {
                a :href<#>, :class<open-link>, :data-target("#$.html-id"), $!button;
            } else {
                a :href<#>, :class<open-link>, :data-target("#$.html-id"), $!label;
            }

            div :class<lightbox-overlay>, :id($.html-id), [
                div :class<lightbox-content>, [
                    span :class<close-btn>, Safe.new: '&times';
                    do-regular-tag( 'div', @.inners, |%.attrs )
                ];
            ];
        ];
    }

    method STYLE {
        q:to/END/;
        .lightbox-overlay {
          position: fixed;
          top: 0; left: 0;
          width: 100%; height: 100%;
          background: rgba(0, 0, 0, 0.8);
          display: none;
          align-items: center;
          justify-content: center;
          z-index: 900;
        }

        .lightbox-overlay.active {
          display: flex;
        }

        .lightbox-content {
          background: grey;
          width: 70vw;
          position: relative;
          border-radius: 10px;
          box-shadow: 0 5px 15px rgba(0,0,0,0.3);
          padding: 1rem;
        }

        .close-btn {
          position: absolute;
          top: 10px;
          right: 15px;
          font-size: 24px;
          color: #333;
          cursor: pointer;
        }
        END
    }

    method SCRIPT {
        q:to/END/;
        // Open specific lightbox
        document.querySelectorAll('.open-link').forEach(link => {
          link.addEventListener('click', e => {
            e.preventDefault();
            const target = document.querySelector(link.dataset.target);
            if (target) target.classList.add('active');
          });
        });

        // Close when clicking the X or outside the content
        document.querySelectorAll('.lightbox-overlay').forEach(lightbox => {
          const content = lightbox.querySelector('.lightbox-content');
          const closeBtn = lightbox.querySelector('.close-btn');

          closeBtn.addEventListener('click', () => {
            lightbox.classList.remove('active');
          });

          lightbox.addEventListener('click', e => {
            if (!content.contains(e.target)) {
              lightbox.classList.remove('active');
            }
          });
        });

        // Close any open lightbox on Escape
        document.addEventListener('keydown', e => {
          if (e.key === 'Escape') {
            document.querySelectorAll('.lightbox-overlay.active').forEach(lb => {
              lb.classList.remove('active');
            });
          }
        });
        END
    }
}

=head2 Other Elements

=head3 role Markdown does Component is export

role Markdown    does Component is export {
    use Text::Markdown;

    #| markdown to be converted
    has Str $.markdown;
    # cache the result
    has Markup() $!result;

    #| .new positional takes Str $code
    multi method new(Str $markdown, *%h) {
        self.bless: :$markdown, |%h;
    }

    multi method HTML {
        $!result = Text::Markdown.new($!markdown).render unless $!result;
        $!result
    }
}


##### Functions Export #####

#| put in all the @components as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}
# viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing

my package EXPORT::DEFAULT {

    for exports-air-base-elements() -> $name {

        OUR::{'&' ~ $name.lc} :=
            sub (*@a, *%h) {
                ::($name).new( |@a, |%h )
            }

    }
}

