package GlobalCategories::Plugin;

use strict;
use warnings;

sub plugin {
    return MT->component('GlobalCategories');
}

sub hdlr_edit_entry_param {
    my ($cb, $app, $param, $tmpl) = @_;
    
    my $blog_id = $app->blog->id;
    my $scope = 'blog:'.$blog_id;
    my $plugin = plugin();
    my $gcat_blog_id = $plugin->get_config_value('gcat_blog_id', $scope);
    return unless $gcat_blog_id;
    
    # Add global categories to current blog categories
    my @gcats = MT->model('category')->load({ blog_id => $gcat_blog_id});
    @gcats = reverse(@gcats);

    # unshift @{$param->{category_tree}}, {
    #     id       => '',
    #     label    => '--------------------',
    #     basename => '',
    #     path     => [],
    #     fields   => [],
    # };
    foreach (@gcats) {
        unshift @{$param->{category_tree}}, {
            id       => $_->id,
            label    => $_->label,
            basename => $_->basename,
            path     => $_->parent || [],
            fields   => [],
        };

    }
    
    # Add styles for global categories
    my $gcats_styles = '';
    foreach (@gcats) {
        $gcats_styles .= 'a.add-category-new-link-id-' . $_->id . '{ display: none !important; }';
    }

    $param->{global_categories_script} = <<"EOD";
<script type="text/javascript">
jQuery(function(){
  jQuery('head').append('<style type="text/css">${gcats_styles}</style>');
});
</script>
EOD
    1;
}

sub hdlr_category_selector_source {
    my ($cb, $app, $tmpl_ref) = @_;
    my $pattern = 'add-category-new-link';
    my $replace = 'add-category-new-link add-category-new-link-id-[#= item.id #]';
    $$tmpl_ref =~ s!$pattern!$replace!;
}

sub hdlr_footer_source {
    my ($cb, $app, $tmpl_ref) = @_;
    my $text = '<mt:var name="global_categories_script">';
    $$tmpl_ref = $text . $$tmpl_ref;
}

1;
