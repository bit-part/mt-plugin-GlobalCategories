package GlobalCategories::Plugin;

use strict;
use warnings;

sub plugin {
    return MT->component('GlobalCategories');
}

sub hdlr_post_save_entry {
    my ($cb, $app, $obj, $org_obj) = @_;

    my $blog_id = $app->blog->id;
    my $scope = 'blog:'.$blog_id;
    my $plugin = plugin();
    my $gcat_blog_id = $plugin->get_config_value('gcat_blog_id', $scope);
    return unless $gcat_blog_id;

    my $category_ids = $app->param('category_ids')
        or return;
    my %category_hash;
    foreach (split /,/, $category_ids) {
        my $key = 'cat_' . $_;
        $category_hash{$key} = $_;
    }
    my $categories = $obj->categories;
    if ($categories) {
        foreach my $cat (@$categories) {
            my $cat_key = 'cat_' . $cat->id;
            delete($category_hash{$cat_key});
        }
        if (%category_hash) {
            foreach my $key (keys(%category_hash)) {
                my $place = MT->model('placement')->new;
                $place->blog_id($gcat_blog_id);
                $place->entry_id($obj->id);
                $place->category_id($category_hash{$key});
                $place->is_primary(0);
                $place->save;
            }
        }
    }
}

sub hdlr_edit_entry_param {
    my ($cb, $app, $param, $tmpl) = @_;

    my $blog_id = $app->blog->id;
    my $scope = 'blog:'.$blog_id;
    my $plugin = plugin();
    my $gcat_blog_id = $plugin->get_config_value('gcat_blog_id', $scope);
    return unless $gcat_blog_id;
    
    # Build a global categories list
    my $gcats = $app->_build_category_list(
        blog_id => $gcat_blog_id,
        markers => 1,
        type    => 'category',
    );
    @$gcats = reverse(@$gcats);


    my @selected_gcats = MT->model('placement')->load({
        blog_id => $gcat_blog_id,
        entry_id => $param->{id},
    });

    if (@selected_gcats) {
        foreach my $selected_gcats (@selected_gcats) {
            push(@{$param->{selected_category_loop}}, $selected_gcats->category_id);
        }
    }

    # unshift @{$param->{category_tree}}, {
    #     id       => '',
    #     label    => '--------------------',
    #     basename => '',
    #     path     => [],
    #     fields   => [],
    # };
    foreach (@$gcats) {
        if ($_->{BEGIN_SUBCATS} || $_->{END_SUBCATS}) {
            next;
        }
        unshift @{$param->{category_tree}}, {
            id       => $_->{category_id},
            label    => $_->{category_label},
            basename => $_->{category_basename},
            path     => $_->{category_path_ids }|| [],
            fields   => [],
        };

    }
    
    # Add styles to hide add buttons of global categories
    my $gcats_styles = '';
    foreach (@$gcats) {
        $gcats_styles .= 'a.add-category-new-link-id-' . $_->{category_id} . '{ display: none !important; }';
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

sub hdlr_template_source_edit_category {
    my ($cb, $app, $tmpl_ref) = @_;

    my $blog_id = $app->blog->id;
    my $scope = 'blog:'.$blog_id;
    my $plugin = plugin();
    my $is_gcat_blog = $plugin->get_config_value('is_gcat_blog', $scope);
    return unless $is_gcat_blog;

    my $text = <<'EOD';
<mt:SetVarBlock name="jq_js_include" append="1">
jQuery('#useful-links .widget-content [href*="&filter=category_id&filter_val"]').each(function () {
  var href = jQuery(this).attr('href');
  href = href.replace(/&filter=category_id/g, '');
  href = href.replace(/&blog_id=\d+/g, '&blog_id=0');
  href = href.replace(/filter_val/g, 'global_category');
  jQuery(this).attr('href', href);
});
</mt:SetVarBlock>
EOD
    $$tmpl_ref = $text . $$tmpl_ref;
}

sub hdlr_template_source_list_category {
    my ($cb, $app, $tmpl_ref) = @_;

    my $blog_id = $app->blog->id;
    my $scope = 'blog:'.$blog_id;
    my $plugin = plugin();
    my $is_gcat_blog = $plugin->get_config_value('is_gcat_blog', $scope);
    return unless $is_gcat_blog;

    my $text = <<'EOD';
<mt:SetVarBlock name="jq_js_include" append="1">
jQuery('#root').on('mouseenter.globalCategory', 'span.count a', function () {
  var href = jQuery(this).attr('href');
  href = href.replace(/&filter=category_id/g, '');
  href = href.replace(/&blog_id=\d+/g, '&blog_id=0');
  href = href.replace(/filter_val/g, 'global_category');
  jQuery(this).attr('href', href);
});
</mt:SetVarBlock>
EOD
    $$tmpl_ref = $text . $$tmpl_ref;
}

sub hdlr_list_template_param_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $blog = $app->blog;
    return if $blog && $blog->id;

    my $q = $app->param;
    my $param_gcat = $q->param('global_category');
    return unless $param_gcat;

    $param_gcat = $param_gcat - 0;
    require JSON;
    my $initial_filter;
    my $initial_filter_json = $param->{initial_filter};
    if ($initial_filter_json) {
        my $gcat = MT->model('category')->load($param_gcat);
        my $cat_label = $gcat->label;
        $initial_filter = JSON::from_json($initial_filter_json);
        $initial_filter->{label} = MT->translate( 'Entries by [_1]', $cat_label, undef);
        $initial_filter->{items} = [
            {
                type => 'category',
                args => {
                    string => $cat_label,
                    option => 'equal',
                }
            }
        ];
        $param->{initial_filter} = JSON::to_json($initial_filter);
    }
}

sub hdlr_global_category_entry_count {
    my ($ctx, $args) = @_;
    (my $category = _get_category_context($ctx))
        || return $ctx->error($ctx->errstr);

    my $count = MT::Entry->count(
        {
            status => MT::Entry::RELEASE()
        },
        {
            join => MT::Placement->join_on(
                'entry_id',
                { category_id => $category->id },
                { unique => 1 }
            ),
        }
    );
    return $count;
}

# lib/MT/Template/Tags/Category.pm
sub _get_category_context {
    my ($ctx) = @_;

    my $tag = $ctx->stash('tag');

    # Get our hands on the category for the current context
    # Either in MTCategories, a Category Archive Template
    # Or the category for the current entry
    my $cat = $ctx->stash('category')
        || $ctx->stash('archive_category');

    if ( !defined $cat ) {

        # No category found so far, test the entry
        if ( $ctx->stash('entry') ) {
            $cat = $ctx->stash('entry')->category;

            # Return empty string if entry has no category
            # as the tag has been used in the correct context
            # but there is no category to work with
            return '' if ( !defined $cat );
        }
        else {
            return $ctx->error(
                MT->translate(
                    "MT[_1] must be used in a [_2] context",
                    $tag,
                        $tag =~ m/folder/ig ? 'folder' : 'category'
                )
            );
        }
    }
    return $cat;
}

1;
