const { Widget } = ags;
const Audio = ags.Service.import('audio');

export default () => Widget.Box({
  className: 'card',
  vertical: true,
  spacing: 8,

  children: [
    Widget.Label({ label: 'Controls', className: 'title' }),

    Widget.Slider({
      hexpand: true,
      drawValue: false,
      value: Audio.bind('speaker').as(s => s.volume),
      onChange: ({ value }) => Audio.speaker.volume = value,
    }),

    Widget.Label({
      label: Audio.bind('speaker').as(s =>
        `🔊 Volume: ${Math.round(s.volume * 100)}%`),
    }),
  ],
});
