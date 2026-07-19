import {ImportWizard} from '@/components/data/import-wizard';
export default function Page(){return <><div className="hero"><div><h1>New Import</h1><p className="muted">Profile, map, validate, preview, and commit a controlled source batch.</p></div><a className="secondary-btn" href="/data-studio/imports">Import history</a></div><ImportWizard/></>}
