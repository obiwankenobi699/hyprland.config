const { Widget } = ags;
const Battery = ags.Service.import('battery');
const Network = ags.Service.import('network');

export default () => Widget.Box({
  className: 'card',
  vertical: true,
  spacing: 8,

  children: [
    Widget.Label({ label: 'System', className: 'title' }),

    Widget.Label({
      label: Battery.bind('percent').as(p => `🔋 Battery: ${p}%`),
    }),

    Widget.Label({
      label: Network.bind('wifi').as(w =>
        w ? `📶 WiFi: ${w.ssid}` : '❌ No WiFi'),
    }),
  ],
});
