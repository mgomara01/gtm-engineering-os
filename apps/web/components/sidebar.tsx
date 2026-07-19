import Link from 'next/link';
import { navigation } from '@/lib/navigation';
export function Sidebar(){return <aside className="sidebar"><div className="brand">GTM Engineering OS</div><div className="navgroup">Workspace</div>{navigation.map(item=>{const Icon=item.icon;return <Link className="navitem" href={item.href} key={item.href}><Icon size={17} style={{verticalAlign:'middle',marginRight:9}}/>{item.label}</Link>})}</aside>}
