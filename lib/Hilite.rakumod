use experimental :rakuast;
use RakuAST::Deparse::Highlight;
use Rainbow;
#use RakuDoc::Render;

#`[
Proposed changes
- do not use Rakudoc::Render
  - drop $rdp param type check from method enable
- multi sub/method templates in the absence of real $tmpl, in the non tmpl case
  - change $tmpl.globals.escape.($_) to HTML::Escape
  - sub escape depends on multi branch
  - since Hilite is HTML only should be OK
- set default-engine is TWEAK (no $rdp available)
- continue to use config (ie for :js-link)
- continue to support attrs (allow, !syntax-highlighting)
- think about
   - $tmpl.globals.helper<add-to-warnings>
   - sub add-to-warnings depends on multi branch

   or maybe I do pass in a faux tmpl that has
   - escape
   - helper<add-to-warnings>

   and maybe I can make a faux rdp the call enable
   - add-templates
   - add-data

   need to check fontawesome
   keep bulma, add picocss
   - new attr :css-lib = bulma | pico
]

unit class Hilite;
has $!default-engine;
has %.config = %(
    :name-space<hilite>,
    :license<Artistic-2.0>,
    :credit<finanalyst, lizmat>,
    :author<<Richard Hainsworth, aka finanalyst\nElizabeth Mattijsen, aka lizmat>>,
    :version<0.1.1>,
    :js-link(
    ['src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js"', 2 ],
    ['src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/languages/haskell.min.js"', 2 ],
    ),
    :css-link(
    ['href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/default.min.css"',1],
    ),
    :js([self.js-text,1],),
    :scss([ self.scss-str, 1], ),
);
has %!hilight-langs = %(
    'HTML' => 'xml',
    'XML' => 'xml',
    'BASH' => 'bash',
    'C' => 'c',
    'C++' => 'cpp',
    'C#' => 'csharp',
    'SCSS' => 'css',
    'SASS' => 'css',
    'CSS' => 'css',
    'MARKDOWN' => 'markdown',
    'DIFF' => 'diff',
    'RUBY' => 'ruby',
    'GO' => 'go',
    'TOML' => 'ini',
    'INI' => 'ini',
    'JAVA' => 'java',
    'JAVASCRIPT' => 'javascript',
    'JSON' => 'json',
    'KOTLIN' => 'kotlin',
    'LESS' => 'less',
    'LUA' => 'lua',
    'MAKEFILE' => 'makefile',
    'PERL' => 'perl',
    'OBJECTIVE-C' => 'objectivec',
    'PHP' => 'php',
    'PHP-TEMPLATE' => 'php-template',
    'PHPTEMPLATE' => 'php-template',
    'PHP_TEMPLATE' => 'php-template',
    'PYTHON' => 'python',
    'PYTHON-REPL' => 'python-repl',
    'PYTHON_REPL' => 'python-repl',
    'R' => 'r',
    'RUST' => 'rust',
    'SCSS' => 'scss',
    'SHELL' => 'shell',
    'SQL' => 'sql',
    'SWIFT' => 'swift',
    'YAML' => 'yaml',
    'TYPESCRIPT' => 'typescript',
    'BASIC' => 'vbnet',
    '.NET' => 'vbnet',
    'HASKELL' => 'haskell',
);
method enable( $rdp ) {
#    method enable( RakuDoc::Processor:D $rdp ) {  #lenny
    $!default-engine = (%*ENV<HIGHLIGHTER> // 'rainbow').lc;
    $rdp.add-templates( $.templates, :source<Hilite plugin> );
    $rdp.add-data( %!config<name-space>, %!config );
}
method TWEAK {
    $!default-engine = (%*ENV<HIGHLIGHTER> // 'rainbow').lc;
}
sub wrapper(str $color, str $c) {
    $c.trim ?? "<span style=\"color:var(--bulma-$color);font-weight:500;\">$c\</span>" !! $c
}
my %mapping = mapper(
    black     => -> $c { wrapper( "black",   $c ) },
    blue      => -> $c { wrapper( "link",    $c ) },
    cyan      => -> $c { wrapper( "info",    $c ) },
    green     => -> $c { wrapper( "primary", $c ) },
    magenta   => -> $c { wrapper( "success", $c ) },
    none      => -> $c { wrapper( "none",    $c ) },
    red       => -> $c { wrapper( "danger",  $c ) },
    yellow    => -> $c { wrapper( "warning", $c ) },
    white     => -> $c { wrapper( "white",   $c ) },
);

method templates {
    constant CUT-LENG = 500; # crop length in error message
    %(
        code => sub (%prm, $tmpl) {

            sub source {   #lenny
                given %prm<contents>.Str.trim-trailing {
#                    $tmpl.globals.escape.($_) //
                    $_
                }
            }

            note 42;
            # if :allow is set, then no highlighting as allow creates alternative styling
            # if :!syntax-highlighting, then no highlighting
            # if :lang is set to a lang in list, then enable highlightjs
            # if :lang is set to lang not in list, not raku or RakuDoc, then no highlighting
            # if :lang is not set, then highlight as Raku

            # select hilite engine
            my $engine = $!default-engine;
            $engine = %prm<highlighter>.lc
            if (%prm<highlighter>:exists && %prm<highlighter> ~~ /:i 'Deparse' | 'Rainbow' /);
            my $code;
            my $syntax-label;
            my $source = %prm<contents>.Str.trim-trailing;
            my Bool $hilite = %prm<syntax-highlighting> // True;
            if %prm<allow> {
                $syntax-label = '<b>allow</b> styling';
                $code = qq:to/NOHIGHS/;
                    <pre class="nohighlights">
                    { $tmpl<escape-code> }
                    </pre>
                    NOHIGHS
            }
            elsif $hilite {
                my $lang = %prm<lang> // 'Raku';
                given $lang.uc {
                    when any( %!hilight-langs.keys ) {
                        $syntax-label = $lang ~  ' highlighting by highlight-js';
                        $code = qq:to/HILIGHT/;
                            <pre class="browser-hl">
                            <code class="language-{ %!hilight-langs{ $_ } }">
                            { source }
                            </code></pre>
                            HILIGHT
                    }
#                    when any( %!hilight-langs.keys ) {
#                        $syntax-label = $lang ~  ' highlighting by highlight-js';
#                        $code = qq:to/HILIGHT/;
#                            <pre class="browser-hl">
#                            <code class="language-{ %!hilight-langs{ $_ } }">
#                            { $tmpl.globals.escape.($source) }
#                            </code></pre>
#                            HILIGHT
#                    }
                    when 'RAKUDOC' {
                        $syntax-label = 'RakuDoc';
                    }
                    when ! /^ 'RAKU' » / {
                        $syntax-label = $lang;
                        $code = qq:to/NOHIGHS/;
                            <pre class="nohighlights">
                            { source }
                            </pre>
                            NOHIGHS
                    }
#                    when ! /^ 'RAKU' » / {
#                        $syntax-label = $lang;
#                        $code = qq:to/NOHIGHS/;
#                            <pre class="nohighlights">
#                            $tmpl.globals.escape.($source)
#                            </pre>
#                            NOHIGHS
#                    }
                    default {
                        $syntax-label = 'Raku highlighting';
                    }
                }
            }
#            else { # no :allow and :!syntax-highlighting
#                $syntax-label = %prm<lang> // 'Text';
#                $code = qq:to/NOHIGHS/;
#                    <pre class="nohighlights">
#                    { $tmpl.globals.escape.($source) }
#                    </pre>
#                    NOHIGHS
#            }
            else { # no :allow and :!syntax-highlighting
                $syntax-label = %prm<lang> // 'Text';
                $code = qq:to/NOHIGHS/;
                    <pre class="nohighlights">
                    { source }
                    </pre>
                    NOHIGHS
            }

            without $code { # so need Raku highlighting
                if $engine eq 'deparse' {
                    # for RakuDoc, deparse needs an explicit =rakudoc block
                    if $syntax-label eq 'RakuDoc' {
#                        $code = $source;
                        $source = "=begin rakudoc\n$source\n=end rakudoc";
                    }
                    my $c = highlight( $source, :unsafe, %mapping);
                    if $c {
                        $code = $c.trim
                    }
#                    else {
#                        my $m = $c.exception.message;
#                        $tmpl.globals.helper<add-to-warnings>( 'Error when highlighting ｢' ~
#                            ( $source.chars > CUT-LENG
#                                ?? ($source.substr(0,CUT-LENG) ~ ' ... ')
#                                !! $source.trim ) ~
#                            '｣' ~ "\nbecause\n$m" );
#                        $code = $source;
#                    }
#                    CATCH {
#                        default {
#                            $tmpl.globals.helper<add-to-warnings>( 'Error in code block with ｢' ~
#                                ( $source.chars > CUT-LENG
#                                    ?? ($source.substr(0,CUT-LENG) ~ ' ... ')
#                                    !! $source.trim ) ~
#                                '｣' ~ "\nbecause\n" ~ .message );
#                            $code = $tmpl.globals.escape.($source);
#                        }
#                    }
                    if $syntax-label eq 'RakuDoc' {
                        $code .= subst(/ '<span' <-[ > ]>+ '>=begin</span> <span' <-[ > ]>+  '>rakudoc</span>' \s*/,'');
                        $code .= subst(/ \s* '<span' <-[ > ]>+ '>=end</span> <span' <-[ > ]>+  '>rakudoc</span>' \s* /,'')
                    }
                }
                else {
                    if $syntax-label eq 'RakuDoc' {
                        $code = Rainbow::tokenize-rakudoc($source).map( -> $t {
                            my $cont = $t.text;
#                            my $cont = $tmpl.globals.escape.($t.text);  #lenny
                            if $t.type.key ne 'TEXT' {
                                qq[<span class="rainbow-{$t.type.key.lc}">$cont\</span>]
                            }
                            else {
                                $cont .= subst(/ ' ' /, '&nbsp;',:g);
                            }
                        }).join('');
                    }
                    else {
                        $code = Rainbow::tokenize($source).map( -> $t {
                            my $cont = $t.text;
#                            my $cont = $tmpl.globals.escape.($t.text);  #lenny
                            if $t.type.key ne 'TEXT' {
                                qq[<span class="rainbow-{$t.type.key.lc}">$cont\</span>]
                            }
                            else {
                                $cont .= subst(/ ' ' /, '&nbsp;',:g);
                            }
                        }).join('');
                    }
                    $code .= subst( / \v+ <?before $> /, '');
                    $code .= subst( / \v /, '<br>', :g);
                    $code .= subst( / "\t" /, '&nbsp' x 4, :g );
                }
                $code = qq:to/NOHIGHS/;
                        <pre class="nohighlights">
                        $code
                        </pre>
                        NOHIGHS
            }

            qq[
                <div class="raku-code">
                    <button class="copy-code" title="Copy code"><i class="far fa-clipboard"></i></button>
                    <label>$syntax-label\</label>
                    <div>$code\</div>
                </div>
            ]
        },
    )
}
method js-text {
    q:to/JSCOPY/;
        // Hilite-helper.js
        document.addEventListener('DOMContentLoaded', function () {
            // trigger the highlighter for non-Raku code
            hljs.highlightAll();

            // copy code block to clipboard adapted from solution at
            // https://stackoverflow.com/questions/34191780/javascript-copy-string-to-clipboard-as-text-html
            // if behaviour problems with different browsers add stylesheet code from that solution.
            const copyButtons = Array.from(document.querySelectorAll('.copy-code'));
            copyButtons.forEach( function( button ) {
            var codeElement = button.nextElementSibling.nextElementSibling; // skip the label and get the div
            button.addEventListener( 'click', function(insideButton) {
                var container = document.createElement('div');
                container.innerHTML = codeElement.innerHTML;
                    container.style.position = 'fixed';
                    container.style.pointerEvents = 'none';
                    container.style.opacity = 0;
                    document.body.appendChild(container);
                    window.getSelection().removeAllRanges();
                    var range = document.createRange();
                    range.selectNode(container);
                    window.getSelection().addRange(range);
                    document.execCommand("copy", false);
                    document.body.removeChild(container);
                });
            });
        });
    JSCOPY
}
method scss-str {
    q:to/SCSS/
    /* Raku code highlighting */
    .raku-code {
        position: relative;
        margin: 1rem 0;
        button.copy-code {
            cursor: pointer;
            opacity: 0;
            padding: 0 0.25rem 0.25rem 0.25rem;
            position: absolute;
        }
        &:hover button.copy-code {
            opacity: 0.5;
        }
        label {
            float: right;
            font-size: xx-small;
            font-style: italic;
            height: auto;
            padding-right: 0;
        }
        /* required to match highlights-js css with raku highlighter css */
        pre.browser-hl { padding: 7px; }

        .code-name {
            padding-top: 0.75rem;
            padding-left: 1.25rem;
            font-weight: 500;
        }
        pre {
            display: inline-block;
            overflow: scroll;
            width: 100%;
        }
        .rakudoc-in-code {
            padding: 1.25rem 1.5rem;
        }
        .section {
            /* https://github.com/Raku/doc-website/issues/144 */
            padding: 0rem;
        }
        .rainbow-name_scalar {
            color: var(--bulma-link-40);
            font-weight:500;
        }
        .rainbow-name_array {
            color: var(--bulma-link);
            font-weight:500;
        }
        .rainbow-name_hash {
            color: var(--bulma-link-60);
            font-weight:500;
        }
        .rainbow-name_code {
            color: var(--bulma-info);
            font-weight:500;
        }
        .rainbow-keyword {
            color: var(--bulma-primary);
            font-weight:500;
        }
        .rainbow-operator {
            color: var(--bulma-success);
            font-weight:500;
        }
        .rainbow-type {
            color: var(--bulma-danger-60);
            font-weight:500;
        }
        .rainbow-routine {
            color: var(--bulma-info-30);
            font-weight:500;
        }
        .rainbow-string {
            color: var(--bulma-info-40);
            font-weight:500;
        }
        .rainbow-string_delimiter {
            color: var(--bulma-primary-40);
            font-weight:500;
        }
        .rainbow-escape {
            color: var(--bulma-black-60);
            font-weight:500;
        }
        .rainbow-text {
            color: var(--bulma-black);
            font-weight:500;
        }
        .rainbow-comment {
            color: var(--bulma-success-30);
            font-weight:500;
        }
        .rainbow-regex_special {
            color: var(--bulma-success-60);
            font-weight:500;
        }
        .rainbow-regex_literal {
            color: var(--bulma-black-60);
            font-weight:500;
        }
        .rainbow-regex_delimiter {
            color: var(--bulma-primary-60);
            font-weight:500;
        }
        .rainbow-rakudoc_text {
            color: var(--bulma-success-40);
            font-weight:500;
        }
        .rainbow-rakudoc_markup {
            color: var(--bulma-danger-40);
            font-weight:500;
        }
    }
    SCSS
}
