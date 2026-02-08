const { Widget } = ags;

import Clock from './clock.js';
import System from './system.js';
import Media from './media.js';
import Controls from './controls.js';

export default () => Widget.Window({
  name: 'dashboard',
  anchor: ['top', 'left', 'right', 'bottom'],
  layer: 'overlay',
  exclusivity: 'ignore',
  keymode: 'on-demand',
  visible: false,

  child: Widget.Box({
    className: 'dashboard',
    vertical: true,
    spacing: 20,

    children: [
      Clock(),
      Widget.Box({
        spacing: 20,
        children: [
          System(),
          Media(),
          Controls(),
        ],
      }),
    ],
  }),
});
