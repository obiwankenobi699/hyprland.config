import { App, Widget } from "astal/gtk4";

const Dashboard = () =>
  Widget.Window({
    name: "dashboard",
    layer: "overlay",
    anchor: ["top", "left", "right", "bottom"],
    visible: false,

    child: Widget.Box({
      vertical: true,
      css: `
        background: rgba(20, 20, 20, 0.9);
        padding: 40px;
      `,
      children: [
        Widget.Label({
          label: "🚀 AGS GTK4 DASHBOARD IS ALIVE",
          css: "font-size: 32px; color: white;",
        }),
      ],
    }),
  });

App.start({
  windows: [Dashboard()],
});
