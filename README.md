# Goblin Slayer 2048

A tactical puzzle game based on 2048 mechanics with a Goblin Slayer theme. Combine goblins to eliminate them and become the ultimate goblin slayer!

## 🎮 Play Now

- **Web Version**: [Play on itch.io](YOUR_ITCH_LINK_HERE)
- **Source Code**: This repository contains the full Vite + React version

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/goblin-slayer-2048.git
cd goblin-slayer-2048
```

2. Install dependencies:
```bash
npm install
# or
yarn install
```

3. Run the development server:
```bash
npm run dev
# or
yarn dev
```

4. Open [http://localhost:9002](http://localhost:9002) in your browser

### Build for Production

```bash
npm run build      # outputs a static site to dist/
npm run preview    # preview the production build locally
```

### Deploying to itch.io

The build is a fully static site (no server required), with relative asset
paths so it works from itch.io's subdirectory hosting:

```bash
npm run build
cd dist && zip -r ../goblin-swiper.zip . && cd ..
```

Then on itch.io: create a new project, set **Kind of project** to *HTML*,
upload `goblin-swiper.zip`, check *This file will be played in the browser*,
and set `index.html` as the entry point.

## 🎯 Game Features

- **Story Mode**: Create a Goblin(256) to win
- **Endless Mode**: Survive infinite goblin waves
- **Progression System**: Earn XP and unlock permanent upgrades
- **Shop System**: Buy powerful items during runs
- **Multilingual**: English and Spanish support
- **Persistent Progress**: Your upgrades and XP are saved

## 🛠️ Tech Stack

- **Build Tool**: Vite 5
- **Library**: React 18
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **UI Components**: Radix UI
- **State Management**: React Hooks
- **Storage**: localStorage for persistence

## 📁 Project Structure

```
index.html              # App entry HTML
src/
├── main.tsx            # React entry point
├── App.tsx             # Main game logic
├── index.css           # Global styles
├── components/         # React components
│   ├── game/          # Game-specific components
│   ├── ui/            # Reusable UI components
│   └── icons/         # Custom icons
├── lib/               # Utility functions
│   ├── utils.ts       # Common utilities
│   └── translations.ts # Internationalization
└── hooks/             # Custom React hooks
```

## 🎮 How to Play

1. **Basic Movement**: Swipe or use arrow keys to move goblins
2. **Combining**: Merge two goblins of the same level to create a stronger one
3. **Combat**: Combined goblins take damage - eliminate them strategically
4. **Survival**: Manage your HP as goblin hordes attack every 15 moves
5. **Progression**: Earn XP to unlock permanent upgrades
6. **Shop**: Find mysterious shops during gameplay to buy powerful items

## 🔧 Development



### Scripts

- `npm run dev` - Start the Vite development server
- `npm run build` - Build the static site to `dist/`
- `npm run preview` - Preview the production build locally
- `npm run typecheck` - Run TypeScript type checking

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎨 Credits

- **Game Design**: Inspired by 2048 and Goblin Slayer
- **Framework**: Built with Vite and React
- **UI**: Powered by Tailwind CSS and Radix UI
- **Icons**: Lucide React

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/covagashi/goblin-slayer-2048/issues) page
2. Create a new issue if your problem isn't already reported
3. For general questions, feel free to start a discussion

---

**Enjoy slaying goblins!** 🗡️👹
