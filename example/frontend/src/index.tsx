import { hydrate, prerender as ssr } from 'preact-iso';
import { useState, useEffect } from 'preact/hooks';
import { AuthClient } from '@icp-sdk/auth/client';

import preactLogo from './assets/preact.svg';
import './style.css';

const identityProvider = import.meta.env.DEV
	? 'http://id.ai.localhost:4943/#authorize'
	: 'https://id.ai/authorize';

export function App() {
	const [authClient, setAuthClient] = useState<AuthClient | null>(null);
	const [isAuthenticated, setIsAuthenticated] = useState(false);
	const [principal, setPrincipal] = useState('');
	const [isReady, setIsReady] = useState(false);

	useEffect(() => {
		const initAuth = async () => {
			const client = new AuthClient({
				identityProvider,
			});

			setAuthClient(client);
			setIsReady(true);

			const authenticated = client.isAuthenticated();
			setIsAuthenticated(authenticated);

			if (authenticated) {
				const identity = await client.getIdentity();
				setPrincipal(identity.getPrincipal().toString());
			}
		};

		initAuth().catch((error) => {
			console.error('AuthClient initialization failed:', error);
		});
	}, []);

	const handleLogin = async () => {
		if (!authClient) {
			console.error('AuthClient is not initialized');
			return;
		}
		try {
			const signInPromise = authClient.signIn();
			await signInPromise;
			const identity = await authClient.getIdentity();
			setIsAuthenticated(true);
			setPrincipal(identity.getPrincipal().toString());
		} catch (error) {
			console.error('Login failed:', error);
		}
	};

	const handleLogout = async () => {
		if (authClient) {
			await authClient.logout();
			setIsAuthenticated(false);
			setPrincipal('');
		}
	};

	return (
		<div>
			<a href="https://preactjs.com" target="_blank">
				<img src={preactLogo} alt="Preact logo" height="160" width="160" />
			</a>
			<h1>Internet Identity ログイン</h1>
			{isAuthenticated ? (
				<div>
					<p>ログインしました</p>
					<p>Principal: {principal}</p>
					<button onClick={handleLogout}>ログアウト</button>
				</div>
			) : (
				<div>
					<p>Internet Identity にログインしてください</p>
					<button onClick={handleLogin} disabled={!isReady}>
						{isReady ? 'ログイン' : '読み込み中...'}
					</button>
				</div>
			)}
		</div>
	);
}

if (typeof window !== 'undefined') {
	hydrate(<App />, document.getElementById('app'));
}

export async function prerender(data) {
	return await ssr(<App {...data} />);
}
