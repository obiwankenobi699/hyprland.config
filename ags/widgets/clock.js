const { Widget } = ags;

export default () => Widget.Box({
  className: 'card',
  vertical: true,

  children: [
    Widget.Label({
      className: 'clock-time',
      label: () => new Date().toLocaleTimeString(),
      poll: [1000],
    }),
    Widget.Label({
      className: 'clock-date',
      label: () => new Date().toDateString(),
      poll: [60000],
    }),
  ],
});
