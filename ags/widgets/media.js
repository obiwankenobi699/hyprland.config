const { Widget } = ags;
const Mpris = ags.Service.import('mpris');

export default () => Widget.Box({
  className: 'card',
  vertical: true,
  spacing: 6,

  children: [
    Widget.Label({ label: 'Media', className: 'title' }),

    Widget.Label({
      label: Mpris.bind('players').as(players =>
        players[0]
          ? `🎵 ${players[0].track_title}`
          : 'Nothing playing'),
    }),

    Widget.Box({
      spacing: 10,
      children: [
        Widget.Button({
          label: '⏮',
          onClicked: () => Mpris.players[0]?.previous(),
        }),
        Widget.Button({
          label: '⏯',
          onClicked: () => Mpris.players[0]?.playPause(),
        }),
        Widget.Button({
          label: '⏭',
          onClicked: () => Mpris.players[0]?.next(),
        }),
      ],
    }),
  ],
});
