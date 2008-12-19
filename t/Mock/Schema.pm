package Mock::Schema;

use DBIx::Skinny::Schema;
use DateTime;
use DateTime::Format::Strptime;
use DateTime::Format::SQLite;
use Data::GUID::URLSafe;
    use Data::Dumper;

install_table tag => schema {
    pk 'id';
    columns qw/id guid name created_at/;

    trigger pre_insert => callback {
        my $args = shift;
        $args->{guid} = Data::GUID->new->as_base64_urlsafe;
        $args->{created_at} = DateTime->now(time_zone => 'Asia/Tokyo');
    };
};

install_utf8_columns qw/name/;
=pod

trigger は
pre_insert, post_insert
pre_update, post_update
pre_delete, post_delete

ということはテーブルが決定しているとみなしてよいのではないか
するとやはり、テーブル単位でトリガー設定をかくべきではないか

pre_search, post_search
にかんしては必要なくてinflate/deflateでやったがよいんじゃないか
inflate/deflateと言うとObjectにしたりとかの意味にとれそうだから
hook?でもきにせずにとりあえずはinflate/deflateでいいんじゃないかなぁ

=cut

install_inflate_rule '^.+_at$' => callback {
    inflate {
        my $value = shift;
        my $dt = DateTime::Format::Strptime->new(
            pattern   => '%Y-%m-%d %H:%M:%S',
            time_zone => 'Asia/Tokyo',
        )->parse_datetime($value);
        return DateTime->from_object( object => $dt );
    };
    deflate {
        my $value = shift;
        return DateTime::Format::SQLite->format_datetime($value);
    };
};

1;

