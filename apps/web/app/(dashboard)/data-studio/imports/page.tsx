import {ImportHistory} from '@/components/data/import-history';
export default function Page(){return <><div className="hero"><div><h1>Import History</h1><p className="muted">Batch manifests, validation outcomes, and rollback state.</p></div><a className="btn" href="/data-studio/imports/new">New import</a></div><section className="section"><ImportHistory/></section></>}
