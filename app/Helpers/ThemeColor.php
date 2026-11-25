<?php

namespace App\Helpers;

/** company_settings.theme_color theke puro site-er primary color-er CSS toiri kore. */
class ThemeColor
{
    public const DEFAULT = '#3699FF';

    public static function normalize(?string $hex): string
    {
        return $hex && preg_match('/^#[0-9a-fA-F]{6}$/', $hex) ? strtoupper($hex) : self::DEFAULT;
    }

    public static function rgb(string $hex): array
    {
        return [hexdec(substr($hex, 1, 2)), hexdec(substr($hex, 3, 2)), hexdec(substr($hex, 5, 2))];
    }

    /** $f > 0 : white-er dike, $f < 0 : black-er dike */
    public static function mix(string $hex, float $f): string
    {
        $t = $f >= 0 ? 255 : 0;
        $f = abs($f);
        return sprintf('#%02X%02X%02X', ...array_map(fn ($c) => (int) round($c + ($t - $c) * $f), self::rgb($hex)));
    }

    public static function css(?string $hex): string
    {
          if (!$hex || !preg_match('/^#[0-9a-fA-F]{6}$/', $hex)) {
        return '';
    }

        $c = self::normalize($hex);
        $active = self::mix($c, -0.12);
        $light = self::mix($c, 0.9);
        [$r, $g, $b] = self::rgb($c);
        $lum = (0.299 * $r + 0.587 * $g + 0.114 * $b) / 255;
        $inv = $lum > 0.72 ? '#181C32' : '#FFFFFF';

        return <<<CSS
:root,[data-bs-theme=light],[data-bs-theme=dark]{--bs-primary:$c;--bs-primary-active:$active;--bs-primary-light:$light;--bs-primary-inverse:$inv;--bs-primary-rgb:$r,$g,$b;--bs-link-color:$c;--bs-link-hover-color:$active;--bs-text-primary:$c;--bs-component-active-bg:$c;--bs-component-hover-color:$c;--bs-component-checked-bg:$c;--bs-app-sidebar-light-menu-link-icon-color:$c;--bs-app-sidebar-light-menu-link-icon-color-hover:$c;--bs-app-sidebar-light-menu-link-icon-color-active:$c;--bs-app-sidebar-light-menu-link-color-hover:$c;--bs-app-sidebar-light-menu-link-color-active:$c;--bs-app-sidebar-light-menu-link-bg-color-active:$light}
.text-primary,.text-hover-primary:hover,.text-active-primary.active,.text-active-primary:hover,a.text-hover-primary:hover{color:$c!important}
.bg-primary,.bg-hover-primary:hover,.bg-active-primary.active{background-color:$c!important;color:$inv}
.bg-light-primary,.bg-hover-light-primary:hover,.bg-active-light-primary.active{background-color:$light!important}
.border-primary,.border-hover-primary:hover,.border-active-primary.active{border-color:$c!important}
.btn.btn-primary,.btn-check:checked+.btn.btn-primary,.btn-check:active+.btn.btn-primary{color:$inv;border-color:$c;background-color:$c}
.btn.btn-primary:hover,.btn.btn-primary:focus,.btn.btn-primary:active,.btn.btn-primary.active,.show>.btn.btn-primary{color:$inv;border-color:$active;background-color:$active!important}
.btn.btn-light-primary{color:$c;border-color:transparent;background-color:$light}
.btn.btn-light-primary:hover,.btn.btn-light-primary:focus,.btn.btn-light-primary:active,.btn.btn-light-primary.active,.show>.btn.btn-light-primary{color:$inv;background-color:$c!important}
.btn.btn-active-primary:hover,.btn.btn-active-primary:active,.btn.btn-active-primary.active,.show>.btn.btn-active-primary{color:$inv;background-color:$c!important;border-color:$c}
.btn.btn-active-light-primary:hover,.btn.btn-active-light-primary.active,.show>.btn.btn-active-light-primary{color:$c;background-color:$light!important}
.btn.btn-active-color-primary:hover,.btn.btn-active-color-primary.active,.show>.btn.btn-active-color-primary,.btn.btn-color-primary{color:$c}
.btn.btn-outline-primary,.btn.btn-bordered-primary{color:$c;border-color:$c}
.btn.btn-outline-primary:hover,.btn.btn-outline-primary.active{color:$inv;background-color:$c}
.badge-primary,.badge.badge-primary{color:$inv;background-color:$c}
.badge-light-primary{color:$c;background-color:$light}
.label.label-primary,.label-light-primary{color:$c}
a{color:var(--bs-link-color)}a:hover{color:var(--bs-link-hover-color)}
.form-check-input:checked,.form-check-input[type=checkbox]:indeterminate{background-color:$c;border-color:$c}
.form-check.form-check-solid .form-check-input:checked{background-color:$c}
.form-switch.form-check-solid .form-check-input:checked{background-color:$c}
.form-control:focus,.form-select:focus,.form-control.form-control-solid:focus,.form-select.form-select-solid:focus{border-color:$c}
.nav-line-tabs .nav-item .nav-link.active,.nav-line-tabs .nav-item .nav-link:hover:not(.disabled),.nav-line-tabs .nav-item.show .nav-link{border-bottom-color:$c;color:$c}
.nav-pills .nav-link.active,.nav-pills .show>.nav-link{background-color:$c;color:$inv}
.page-item.active .page-link{background-color:$c;border-color:$c;color:$inv}
.page-link:hover{color:$c}
.progress-bar{background-color:$c}
.dropdown-item.active,.dropdown-item:active{background-color:$c;color:$inv}
.menu-state-primary .menu-item .menu-link:hover:not(.disabled):not(.active):not(.here),.menu-state-primary .menu-sub .menu-item .menu-link.active{color:$c}
.menu-state-title-primary .menu-item .menu-link:hover .menu-title,.menu-state-title-primary .menu-sub .menu-item .menu-link.active .menu-title{color:$c}
.menu-state-icon-primary .menu-item .menu-link:hover .menu-icon .svg-icon,.menu-state-icon-primary .menu-item .menu-link.active .menu-icon .svg-icon,.menu-state-icon-primary .menu-item .menu-link:hover .menu-icon i,.menu-state-icon-primary .menu-item .menu-link.active .menu-icon i{color:$c}
.menu-state-bg-light-primary .menu-item .menu-link:hover:not(.disabled):not(.active),.menu-state-bg-light-primary .menu-sub .menu-item .menu-link.active{background-color:$light;color:$c}
.menu-state-bullet-primary .menu-item .menu-link.active .menu-bullet .bullet,.menu-state-bullet-primary .menu-item .menu-link:hover .menu-bullet .bullet{background-color:$c}
.app-sidebar .menu-sub .menu-item .menu-link.active{color:$c}
.app-sidebar .menu .menu-link>i,.app-sidebar .menu .menu-link .menu-icon i,.app-sidebar .menu .menu-link .menu-icon .svg-icon,.app-sidebar .menu .menu-link .menu-icon .svg-icon svg [fill]:not(.permanent):not(g),.app-sidebar .menu .menu-link .svg-icon-success svg [fill]:not(.permanent):not(g),.app-sidebar .menu .menu-link .svg-icon.svg-icon-success{color:$c!important;fill:$c}
.app-sidebar .menu .menu-link>i::before{color:$c!important}
.app-sidebar .menu .menu-link .menu-icon .svg-icon svg [fill]:not(.permanent):not(g),.app-sidebar .menu .menu-link .svg-icon svg [fill]:not(.permanent):not(g){fill:$c!important}
.app-sidebar .menu-sub .menu-item .menu-link.active,.app-sidebar .menu-sub .menu-item .menu-link.active .menu-title{color:$c!important}
.app-sidebar .menu-sub .menu-item .menu-link.active{background-color:$light!important}
.app-sidebar .menu>.menu-item.here>.menu-link,.app-sidebar .menu>.menu-item.show>.menu-link{background-color:transparent!important}
.app-sidebar .menu .menu-link .menu-bullet .bullet,.app-sidebar .menu .menu-link.active .menu-bullet .bullet{background-color:$c}
.app-header-primary{background-color:$c}
.svg-icon.svg-icon-primary,.svg-icon-primary .svg-icon,.svg-icon.svg-icon-primary svg [fill]:not(.permanent):not(g){fill:$c}
.bullet.bullet-primary,.symbol.symbol-light-primary .symbol-label,.symbol-label.bg-light-primary{background-color:$light;color:$c}
.table-primary{--bs-table-bg:$light}
.alert-primary{color:$c;background-color:$light;border-color:$light}
.scrolltop{background-color:$c}
.swal2-styled.swal2-confirm,.swal2-confirm.btn-primary{background-color:$c!important}
.select2-container--bootstrap5 .select2-results__option--highlighted,.select2-container--bootstrap5 .select2-results__option--selected{background-color:$c;color:$inv}
.page-item .page-link.active,.dataTables_wrapper .paginate_button.current{background-color:$c!important;color:$inv!important}
.flatpickr-day.selected,.flatpickr-day.selected:hover,.flatpickr-day.startRange,.flatpickr-day.endRange{background:$c;border-color:$c}
.bootstrap-select .dropdown-menu li.active a,.bootstrap-select .dropdown-menu li a:active{background-color:$c}
CSS;
    }
}